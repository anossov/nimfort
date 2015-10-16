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

import renderer/components
import renderer/deferred
import renderer/shadowmap

type 
  RenderSystem* = ref object
    view*: Transform
    windowSize*: vec2

    projection3d: mat4
    projection2d: mat4

    queue3d: ComponentStore[Renderable3d]
    lights: ComponentStore[Light]
    queue2d: ComponentStore[Renderable2d]

    shaderText: Program
    
    shadowMap: ShadowMap
    geometryPass: GeometryPass
    lightingPass: LightingPass
    
    listener: Listener


var Renderer*: RenderSystem


proc attach*(e: EntityHandle, r: Renderable3d) =
  Renderer.queue3d.add(e, r)

proc attach*(e: EntityHandle, r: Renderable2d) =
  Renderer.queue2d.add(e, r)

proc getRenderable2d*(e: EntityHandle): var Renderable2d =
  return Renderer.queue2d[e]


proc initRenderSystem*() =
  loadExtensions()
  
  Renderer = RenderSystem(
    queue3d: newComponentStore[Renderable3d](),
    queue2d: newComponentStore[Renderable2d](),
    geometryPass: newGeometryPass(),
    lightingPass: newLightingPass(),
    shadowMap: newShadowMap(),
  )
  Renderer.windowSize = windowSize()

  let
    w = Renderer.windowSize.x
    h = Renderer.windowSize.y

  glEnable(GL_MULTISAMPLE)
  glEnable(GL_FRAMEBUFFER_SRGB)
  glClearColor(0.0, 0.0, 0.0, 1.0)

  Renderer.projection3d = perspective(60.0, w / h, 0.1, 100.0)
  Renderer.projection2d = orthographic(0.0, w, 0.0, h)
  Renderer.view = newTransform(vec(0.0, 0.0, 0.0), zeroes3, ones3)

  Renderer.shaderText = Resources.getShader("text")

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

  let lp = orthographic(-2.0, 2.0, -2.0, 2.0, 2, 10.0)
  let lv = lookAt(light, zeroes3, yaxis)
  var ls = lp * lv

  r.geometryPass.perform(viewMat, r.projection3d, r.queue3d.data)
  r.shadowMap.render(ls, r.queue3d.data)
  r.lightingPass.perform(ls, light, r.view.position, r.geometryPass, r.shadowMap)

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
