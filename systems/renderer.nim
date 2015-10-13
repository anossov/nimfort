import logging
import opengl
import vector
import mesh
import gl/shader
import timekeeping

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
    window*: vec2
    time: TimeSystem
    projection3d: mat4
    projection2d: mat4

    queue3d*: seq[Renderable]
    queue2d*: seq[Renderable]

    shaderMain: Program
    shaderText: Program

    wire: bool

proc updateMatrix*(t: var Transform) = 
  let rot = rotate(xaxis, t.rotation.x) * rotate(yaxis, t.rotation.y) * rotate(zaxis, t.rotation.z)
  t.matrix = translate(t.position) * rot * scale(t.scale)

proc newTransform*(p: vec3, r=zeroes3, s=ones3): Transform = 
  result.position = p
  result.rotation = r
  result.scale = s
  result.updateMatrix()

proc newRenderSystem*(time: TimeSystem, w, h: float32): RenderSystem =
  loadExtensions()
  info("OpenGL version $1", cast[cstring](glGetString(GL_VERSION)))

  result = RenderSystem()
  result.window = [w, h]
  result.time = time

  glViewport(0, 0, w.GLsizei, h.GLsizei)
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_MULTISAMPLE)
  glEnable(GL_FRAMEBUFFER_SRGB)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
  glClearColor(0.3, 0.3, 0.3, 1.0)

  result.projection3d = perspective(60.0, w / h, 0.1, 100.0)
  result.projection2d = orthographic(0.0, w, 0.0, h)

  result.queue3d = newSeq[Renderable]()
  result.queue2d = newSeq[Renderable]()

  result.shaderMain = createProgram(readFile("assets/shaders/main.vs.glsl"), readFile("assets/shaders/main.fs.glsl"))
  result.shaderText = createProgram(readFile("assets/shaders/text.vs.glsl"), readFile("assets/shaders/text.fs.glsl"))

proc render(r: Renderable, s: var Program) = 
  var model = r.transform.matrix
  s["model"].set(model)
  r.mesh.render()

proc render*(r: var RenderSystem) = 
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

proc wire*(r: RenderSystem, yes: bool) = 
  if yes != r.wire:
    if not r.wire:
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
      r.wire = true
    else:
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
      r.wire = false