import logging
import opengl
import vector
import mesh
import math
import gl/shader
import systems/messaging
import systems/timekeeping
import systems/windowing
import systems/input

type 
  Transform* = object
    rotation*: vec3
    position: vec3
    scale: vec3
    matrix: mat4

  Renderable* = object
    transform*: Transform
    mesh*: Mesh

  RenderSystem* = ref object
    view*: Transform
    windowSize*: vec2

    projection3d: mat4
    projection2d: mat4

    queue3d*: seq[Renderable]
    queue2d*: seq[Renderable]

    shaderMain: Program
    shaderText: Program

    listener: Listener


var Renderer*: RenderSystem


proc updateMatrix*(t: var Transform) = 
  let rot = rotate(xaxis, t.rotation.x) * rotate(yaxis, t.rotation.y) * rotate(zaxis, t.rotation.z)
  t.matrix = translate(t.position) * rot * scale(t.scale)


proc newTransform*(p: vec3, r=zeroes3, s=ones3): Transform = 
  result.position = p
  result.rotation = r
  result.scale = s
  result.updateMatrix()


proc initRenderSystem*() =
  loadExtensions()
  
  Renderer = RenderSystem()
  Renderer.windowSize = windowSize()

  let
    w = Renderer.windowSize.x
    h = Renderer.windowSize.y

  glViewport(0, 0, w.GLsizei, h.GLsizei)
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_MULTISAMPLE)
  glEnable(GL_FRAMEBUFFER_SRGB)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
  glClearColor(0.3, 0.3, 0.3, 1.0)

  Renderer.projection3d = perspective(60.0, w / h, 0.1, 100.0)
  Renderer.projection2d = orthographic(0.0, w, 0.0, h)
  Renderer.view = newTransform(vec(0.0, 0.0, 0.0), zeroes3, ones3)

  Renderer.queue3d = newSeq[Renderable]()
  Renderer.queue2d = newSeq[Renderable]()

  Renderer.shaderMain = createProgram(readFile("assets/shaders/main.vs.glsl"), readFile("assets/shaders/main.fs.glsl"))
  Renderer.shaderText = createProgram(readFile("assets/shaders/text.vs.glsl"), readFile("assets/shaders/text.fs.glsl"))

  Renderer.listener = newListener()
  Messages.listen("wire-on", Renderer.listener)
  Messages.listen("wire-off", Renderer.listener)

  info("Renderer ok: OpenGL v. $1", cast[cstring](glGetString(GL_VERSION)))


proc render(r: Renderable, s: var Program) = 
  var model = r.transform.matrix
  s["model"].set(model)
  r.mesh.render()


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
  r.shaderMain.use()
  r.shaderMain["eye"].set(r.view.position)
  r.shaderMain["view"].set(viewMat)
  r.shaderMain["projection"].set(r.projection3d)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glEnable(GL_DEPTH_TEST)
  for i in r.queue3d:
    i.render(r.shaderMain)

  glDisable(GL_DEPTH_TEST)
  r.shaderText.use()
  r.shaderText["projection"].set(r.projection2d)
  for i in r.queue2d:
    i.render(r.shaderText)

  setLen(r.queue3d, 0)
  setLen(r.queue2d, 0)