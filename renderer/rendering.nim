import logging
import opengl
import vector
import math
import gl/framebuffer
import systems/ecs
import systems/messaging
import systems/timekeeping
import systems/camera

import renderer/components
import renderer/screen
import renderer/deferred
import renderer/shadowmap
import renderer/textrenderer
import renderer/postprocess
import renderer/smaa

type
  RenderSystem* = ref object
    shadowMap: ShadowMap
    geometryPass: GeometryPass
    lightingPass: LightingPass
    textRenderer: TextRenderer
    bloom: Bloom
    tonemapping: Tonemapping
    smaa: SMAA
    listener: Listener


var Renderer*: RenderSystem


proc initRenderSystem*() =
  loadExtensions()
  initScreen()

  Renderer = RenderSystem(
    geometryPass: newGeometryPass(),
    lightingPass: newLightingPass(),
    shadowMap: newShadowMap(),
    textRenderer: newTextRenderer(),
    bloom: newBloom(),
    tonemapping: newTonemapping(),
    smaa: newSMAA(),
  )

  glClearColor(0.0, 0.0, 0.0, 0.0)
  glEnable(GL_CULL_FACE)
  glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)
  glEnable(GL_FRAMEBUFFER_SRGB)

  Renderer.listener = newListener()
  Messages.listen("wire-on", Renderer.listener)
  Messages.listen("wire-off", Renderer.listener)

  info("Renderer ok: OpenGL v. $1", cast[cstring](glGetString(GL_VERSION)))


# TODO: maybe Tile-Based DR
# HBAO
# Hi-Z Screen-Space Cone-Traced Reflections

proc render*() =
  var r = Renderer
  var dfb = Framebuffer(target: FramebufferTarget.Both, id: 0)

  for m in r.listener.queue:
    case m:
    of "wire-on":
      glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
    of "wire-off":
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
    else:
      discard

  r.geometryPass.perform()

  for light in mitems(LightStore().data):
    r.shadowMap.render(light)

  r.lightingPass.perform(r.geometryPass, r.bloom.fb_in)
  r.bloom.perform(r.tonemapping.fb_in)
  r.tonemapping.perform(r.smaa.fb_in)
  r.smaa.perform(dfb)

  r.textRenderer.render(Screen.projection)
