import logging
import opengl
import vector
import mesh
import math
import gl/shader
import gl/texture
import gl/framebuffer
import systems/ecs
import systems/messaging
import systems/timekeeping
import systems/windowing
import systems/input
import systems/resources
import config


type 
  RenderSystem* = ref object
    view*: Transform
    windowSize*: vec2

    projection3d: mat4
    projection2d: mat4

    queue3d: ComponentStore[Renderable3d]
    lights: ComponentStore[Light]
    queue2d: ComponentStore[Renderable2d]

    shaderMain: Program
    shaderText: Program
    
    shaderSM: Program

    geometryPass: GeometryPass
    
    shadowMap: ShadowMap
    screenQuad: Mesh

    listener: Listener

  ShadowMap = object
    buffer: Framebuffer
    texture: Texture


var Renderer*: RenderSystem


proc attach*(e: EntityHandle, r: Renderable3d) =
  Renderer.queue3d.add(e, r)

proc attach*(e: EntityHandle, r: Renderable2d) =
  Renderer.queue2d.add(e, r)

proc getRenderable2d*(e: EntityHandle): var Renderable2d =
  return Renderer.queue2d[e]





proc newShadowMap(size: int32): ShadowMap =
  var
    b = newFramebuffer()
    t = newTexture()

  t.image2d(nil, size, size, false, TextureFormat.Depth, PixelType.Float, GL_DEPTH_COMPONENT)
  t.filter(true)

  glTexParameteri(ord t.target, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE)
  glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)

  var border = [1'f32, 1, 1, 1]
  glTexParameterfv(ord t.target, GL_TEXTURE_BORDER_COLOR, addr border[0])

  b.attach(t, depth=true)

  glDrawBuffer(GL_NONE)
  glReadBuffer(GL_NONE)

  debug("Shadow map: $1", b.check())

  return ShadowMap(buffer: b, texture: t)


proc initRenderSystem*() =
  loadExtensions()
  let dummyt = newTexture()
  let quad = MeshData(
    vertices: @[
      Vertex(position: [-1.0'f32,  1.0, 0.0], uv: [0.0'f32, 1.0]),
      Vertex(position: [-1.0'f32, -1.0, 0.0], uv: [0.0'f32, 0.0]),
      Vertex(position: [ 1.0'f32,  1.0, 0.0], uv: [1.0'f32, 1.0]),
      Vertex(position: [ 1.0'f32, -1.0, 0.0], uv: [1.0'f32, 0.0]),
    ],
    indices: @[0'u32, 2, 1, 2, 3, 1]
  )
  Renderer = RenderSystem(
    queue3d: newComponentStore[Renderable3d](),
    queue2d: newComponentStore[Renderable2d](),
    screenQuad: newMesh(quad, dummyt),
    geometryPass: newGeometryPass(),
    shadowMap: newShadowMap(shadowMapSize),
  )
  Renderer.windowSize = windowSize()

  let
    w = Renderer.windowSize.x
    h = Renderer.windowSize.y

  glViewport(0, 0, w.GLsizei, h.GLsizei)
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_MULTISAMPLE)
  glEnable(GL_FRAMEBUFFER_SRGB)
  
  glClearColor(0.0, 0.0, 0.0, 1.0)

  Renderer.projection3d = perspective(60.0, w / h, 0.1, 100.0)
  Renderer.projection2d = orthographic(0.0, w, 0.0, h)
  Renderer.view = newTransform(vec(0.0, 0.0, 0.0), zeroes3, ones3)

  Renderer.shaderMain = Resources.getShader("main")
  Renderer.shaderText = Resources.getShader("text")
  Renderer.shaderG = 
  Renderer.shaderSM = Resources.getShader("shadowmap")

  Renderer.shaderMain.use()
  Renderer.shaderMain.getUniform("gPosition").set(0)
  Renderer.shaderMain.getUniform("gNormal").set(1)
  Renderer.shaderMain.getUniform("gAlbedoSpec").set(2)
  Renderer.shaderMain.getUniform("shadowMap").set(3)

  Renderer.listener = newListener()
  Messages.listen("wire-on", Renderer.listener)
  Messages.listen("wire-off", Renderer.listener)

  info("Renderer ok: OpenGL v. $1", cast[cstring](glGetString(GL_VERSION)))


# TODO: MSAA or maybe SMAA
# TODO: maybe Tile-Based DR

proc render*() = 
  var r = Renderer

  for m in r.listener.queue:
    case m:
    of "wire-on":
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
    of "wire-off":
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
    else:
      discard

  var
    phi = (r.windowSize.x - Input.cursorPos.x) / 200
    theta = (r.windowSize.y - Input.cursorPos.y) / 200
  
  if theta < PI * 0.51:
    theta = PI * 0.51
  if theta > PI * 1.49:
    theta = PI * 1.49

  r.view.position.x = sin(phi) * cos(theta) * 3
  r.view.position.y = sin(theta) * 3
  r.view.position.z = cos(phi) * cos(theta) * 3

  var viewMat = lookAt(r.view.position, zeroes3, yaxis)
  var light = vec(sin(Time.totalTime / 10.0)*5, 5.0, cos(Time.totalTime / 10.0)*5)

  r.geometryPass.perform(viewMat, r.projection3d, r.queue3d.data)

  r.shadowMap.buffer.use()
  glClear(GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, shadowMapSize, shadowMapSize)
  
  let lp = orthographic(-2.0, 2.0, -2.0, 2.0, 2, 10.0)
  let lv = lookAt(light, zeroes3, yaxis)
  var ls = lp * lv
  
  r.shaderSM.use()
  r.shaderSM.getUniform("lightspace").set(ls)

  for i in r.queue3d.data:
    var model = i.transform.matrix
    r.shaderSM.getUniform("model").set(model)
    i.mesh.render()

  glViewport(0, 0, r.windowSize.x.GLsizei, r.windowSize.y.GLsizei)
  useDefaultFramebuffer()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  r.shaderMain.use()
  r.shaderMain.getUniform("eye").set(r.view.position)
  r.shaderMain.getUniform("light").set(light)
  r.shaderMain.getUniform("lightspace").set(ls)
  
  r.gBuffer.position.use(0)
  r.gBuffer.normal.use(1)
  r.gBuffer.albedo.use(2)
  r.shadowmap.texture.use(3)

  r.screenQuad.render()


  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 

  r.shaderText.use()
  r.shaderText.getUniform("projection").set(r.projection2d)
  for i in r.queue2d.data:
    var model = i.transform.matrix
    r.shaderText.getUniform("model").set(model)
    i.mesh.texture.use(0)
    i.mesh.render()
