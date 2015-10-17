import logging
import opengl
import vector
import math
import systems/ecs
import systems/messaging
import systems/timekeeping
import systems/windowing
import systems/camera

import renderer/components
import renderer/deferred
import renderer/shadowmap
import renderer/textrenderer

type
  RenderSystem* = ref object
    windowSize*: vec2
    projection2d: mat4

    models: ComponentStore[Model]
    lights: ComponentStore[Light]
    labels: ComponentStore[Label]

    shadowMap: ShadowMap
    geometryPass: GeometryPass
    lightingPass: LightingPass
    textRenderer: TextRenderer

    listener: Listener

var Renderer*: RenderSystem

proc attach*(e: EntityHandle, r: Model) =
  Renderer.models.add(e, r)

proc attach*(e: EntityHandle, r: Label) =
  Renderer.labels.add(e, r)

proc attach*(e: EntityHandle, r: Light) =
  Renderer.lights.add(e, r)

proc getLabel*(e: EntityHandle): var Label =
  return Renderer.labels[e]

proc getLight*(e: EntityHandle): var Light =
  return Renderer.lights[e]

proc initRenderSystem*() =
  loadExtensions()
  
  Renderer = RenderSystem(
    models: newComponentStore[Model](),
    lights: newComponentStore[Light](),
    labels: newComponentStore[Label](),
    geometryPass: newGeometryPass(),
    lightingPass: newLightingPass(),
    shadowMap: newShadowMap(),
    textRenderer: newTextRenderer(),
  )
  Renderer.windowSize = windowSize()

  let
    w = Renderer.windowSize.x
    h = Renderer.windowSize.y

  glEnable(GL_MULTISAMPLE)
  glEnable(GL_FRAMEBUFFER_SRGB)
  glClearColor(0.0, 0.0, 0.0, 1.0)

  Renderer.projection2d = orthographic(0.0, w, 0.0, h)

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

  r.geometryPass.perform(r.models.data)

  for light in mitems(r.lights.data):
    r.shadowMap.render(light, r.models.data)

  r.lightingPass.perform(r.lights.data, r.geometryPass)

  r.textRenderer.render(r.projection2d, r.labels.data)