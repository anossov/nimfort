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

    gBuffer: GBuffer
    screenQuad: Mesh

    listener: Listener

  GBuffer = ref object
    buffer: Framebuffer
    albedo: Texture
    normal: Texture
    position: Texture


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


proc newGBuffer*(w: int32, h: int32): GBuffer =
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
    screenQuad: newMesh(quad, dummyt)
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

  Renderer.gBuffer = newGBuffer(w.int32, h.int32)

  Renderer.shaderMain = Resources.getShader("main")
  Renderer.shaderText = Resources.getShader("text")
  Renderer.shaderG = Resources.getShader("gbuffer")

  Renderer.shaderMain.use()
  Renderer.shaderMain.getUniform("gPosition").set(0)
  Renderer.shaderMain.getUniform("gNormal").set(1)
  Renderer.shaderMain.getUniform("gAlbedoSpec").set(2)
  

  info("GBuffer: $1", Renderer.gBuffer.buffer.check())

  Renderer.listener = newListener()
  Messages.listen("wire-on", Renderer.listener)
  Messages.listen("wire-off", Renderer.listener)

  info("Renderer ok: OpenGL v. $1", cast[cstring](glGetString(GL_VERSION)))

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
    phi = (r.windowSize.x - Input.cursorPos.x) / 100
    theta = (r.windowSize.y - Input.cursorPos.y) / 100
  
  if theta < PI * 0.51:
    theta = PI * 0.51
  if theta > PI * 1.49:
    theta = PI * 1.49

  r.view.position.x = sin(phi) * cos(theta) * 3
  r.view.position.y = sin(theta) * 3
  r.view.position.z = cos(phi) * cos(theta) * 3

  var viewMat = lookAt(r.view.position, zeroes3, yaxis)

  r.gBuffer.buffer.use()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glEnable(GL_DEPTH_TEST)
  glDisable(GL_BLEND)
  r.shaderG.use()
  r.shaderG.view.set(viewMat)
  r.shaderG.projection.set(r.projection3d)
  
  for i in r.queue3d.data:
    var model = i.transform.matrix
    r.shaderG.model.set(model)
    i.mesh.texture.use(0)
    i.mesh.render()


  useDefaultFramebuffer()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  r.shaderMain.use()
  r.shaderMain.eye.set(r.view.position)
  r.gBuffer.position.use(0)
  r.gBuffer.normal.use(1)
  r.gBuffer.albedo.use(2)
  r.screenQuad.render()


  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 

  r.shaderText.use()
  r.shaderText.projection.set(r.projection2d)
  for i in r.queue2d.data:
    var model = i.transform.matrix
    r.shaderText.model.set(model)
    i.mesh.texture.use(0)
    i.mesh.render()