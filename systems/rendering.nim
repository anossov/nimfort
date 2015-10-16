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
  Transform* = object
    rotation*: vec3
    position: vec3
    scale: vec3
    matrix: mat4

  Renderable3d* = object of Component
    transform*: Transform
    mesh*: Mesh

  Renderable2d* = object of Component
    transform*: Transform
    mesh*: Mesh

  RenderSystem* = ref object
    view*: Transform
    windowSize*: vec2

    projection3d: mat4
    projection2d: mat4

    queue3d: ComponentStore[Renderable3d]
    queue2d: ComponentStore[Renderable2d]

    shaderMain: Program
    shaderText: Program
    shaderG: Program
    shaderSM: Program

    gBuffer: GBuffer
    shadowMap: ShadowMap
    screenQuad: Mesh

    listener: Listener

  GBuffer = object
    buffer: Framebuffer
    albedo: Texture
    normal: Texture
    position: Texture

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


proc updateMatrix*(t: var Transform) = 
  let rot = rotate(xaxis, t.rotation.x) * rotate(yaxis, t.rotation.y) * rotate(zaxis, t.rotation.z)
  t.matrix = translate(t.position) * rot * scale(t.scale)


proc newTransform*(p: vec3, r=zeroes3, s=ones3): Transform = 
  result.position = p
  result.rotation = r
  result.scale = s
  result.updateMatrix()


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


proc newGBuffer(w: int32, h: int32): GBuffer =
  var p, n, a: Texture
  var b = newFramebuffer()
  p = newTexture()
  p.image2d(nil, w, h, false, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  p.filter(false)
  
  n = newTexture()
  n.image2d(nil, w, h, false, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  n.filter(false)
  
  a = newTexture()
  a.image2d(nil, w, h, false, TextureFormat.RGBA, internalformat=GL_RGBA)
  a.filter(false)

  b.attach(p)
  b.attach(n)
  b.attach(a)
  b.attachDepthStencilRBO(w, h)

  debug("GBuffer: $1", b.check())

  return GBuffer(
    buffer: b,
    position: p,
    normal: n,
    albedo: a,
  )

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
    gBuffer: newGBuffer(windowWidth, windowHeight),
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
  Renderer.shaderG = Resources.getShader("gbuffer")
  Renderer.shaderSM = Resources.getShader("shadowmap")

  Renderer.shaderMain.use()
  Renderer.shaderMain.getUniform("gPosition").set(0)
  Renderer.shaderMain.getUniform("gNormal").set(1)
  Renderer.shaderMain.getUniform("gAlbedoSpec").set(2)
  Renderer.shaderMain.getUniform("shadowMap").set(3)

  Renderer.shaderG.use()
  Renderer.shaderG.getUniform("normalmap").set(1)
  Renderer.shaderG.getUniform("specularmap").set(2)
  
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

  glEnable(GL_DEPTH_TEST)

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


  r.gBuffer.buffer.use()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, r.windowSize.x.GLsizei, r.windowSize.y.GLsizei)
  
  glDisable(GL_BLEND)
  r.shaderG.use()
  r.shaderG.getUniform("view").set(viewMat)
  r.shaderG.getUniform("projection").set(r.projection3d)

  
  for i in r.queue3d.data:
    var model = i.transform.matrix
    r.shaderG.getUniform("model").set(model)
    i.mesh.texture.use(0)
    i.mesh.normalmap.use(1)
    i.mesh.specularmap.use(2)
    i.mesh.render()


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
