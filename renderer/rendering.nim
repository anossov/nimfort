import logging
import opengl
import strutils
import vector
import math
import gl/framebuffer
import gl/shader
import gl/texture
import mesh
import systems/ecs
import systems/messaging
import systems/timekeeping
import systems/camera
import systems/resources

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
    debug: Program

    debugMode: string


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
    debug: getShader("debug"),
    debugmode: "",
  )

  glClearColor(0.0, 0.0, 0.0, 0.0)
  glEnable(GL_CULL_FACE)
  glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)
  glEnable(GL_FRAMEBUFFER_SRGB)

  Renderer.listener = newListener()
  Renderer.listener.listen("debug")

  info("Renderer ok: OpenGL v. $1", cast[cstring](glGetString(GL_VERSION)))


# TODO: maybe Tile-Based DR
# HBAO
# Hi-Z Screen-Space Cone-Traced Reflections

proc render*() =
  var r = Renderer
  var dfb = Framebuffer(target: FramebufferTarget.Both, id: 0)

  for m in r.listener.getMessages():
    if r.debugmode == m:
      r.debugmode = ""
    else:
      r.debugmode = m

  if r.debugmode == "wire":
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
  else:
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  r.geometryPass.perform()

  for light in mitems(LightStore().data):
    r.shadowMap.render(light)

  r.lightingPass.perform(r.geometryPass, r.bloom.fb_in)
  r.bloom.perform(r.tonemapping.fb_in)
  r.tonemapping.perform(r.smaa.fb_in)
  r.smaa.perform(dfb)

  if r.debugmode != "":
    r.debug.use()
    case r.debugmode:
      of "albedo", "wire":
        r.geometryPass.albedo.use(0)
        r.debug.getUniform("alpha").set(false)
      of "roughness":
        r.geometryPass.albedo.use(0)
        r.debug.getUniform("alpha").set(true)
      of "normal":
        r.geometryPass.normal.use(0)
        r.debug.getUniform("alpha").set(false)
      of "metalness":
        r.geometryPass.normal.use(0)
        r.debug.getUniform("alpha").set(true)
      of "edges":
        r.smaa.t_edge.use(0)
        r.debug.getUniform("alpha").set(false)
      else:
        discard
    Screen.quad.render()

  r.textRenderer.render(Screen.projection)
