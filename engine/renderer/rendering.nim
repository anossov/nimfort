import logging
import opengl
import strutils
import math

import gl/framebuffer
import gl/shader
import gl/texture

import engine/vector
import engine/mesh
import engine/ecs
import engine/messaging
import engine/timekeeping
import engine/camera
import engine/resources

import engine/renderer/components
import engine/renderer/screen
import engine/renderer/deferred
import engine/renderer/shadowmap
import engine/renderer/textrenderer
import engine/renderer/postprocess
import engine/renderer/smaa
import engine/renderer/ssao
import engine/geometry/aabb

type
  RenderSystem* = ref object
    shadowMap: ShadowMap
    geometryPass: GeometryPass
    lightingPass: LightingPass
    textRenderer: TextRenderer
    bloom: Bloom
    tonemapping: Tonemapping
    smaa: SMAA
    ssao: SSAO
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
    ssao: newSSAO(),
    debug: getShader("debug"),
    debugmode: "",
  )

  glClearColor(0.0, 0.0, 0.0, 0.0)
  glEnable(GL_CULL_FACE)
  glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)

  Renderer.listener = newListener()
  Renderer.listener.listen("debug")

  info("Renderer ok: OpenGL v.", cast[cstring](glGetString(GL_VERSION)))


# TODO: maybe Tile-Based DR
# HBAO
# Hi-Z Screen-Space Cone-Traced Reflections

proc render*() =
  meshesRendered = 0

  var r = Renderer
  var dfb = Framebuffer(target: FramebufferTarget.Both, id: 0)

  for m in r.listener.getMessages():
    if r.debugmode == m.name:
      r.debugmode = ""
    else:
      r.debugmode = m.name

  if r.debugmode == "wire":
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
  else:
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  r.geometryPass.perform()

  let camera_bb = newAABB(Camera.frustum)
  for light in mitems(LightStore().data):
    if light.boundingBox.outside(camera_bb): continue
    r.shadowMap.render(light)

  r.ssao.perform(r.geometryPass.depth, r.geometryPass.normal)

  r.lightingPass.perform(r.geometryPass, r.ssao.occlusion, r.bloom.fb_in)
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
      of "depth":
        r.geometryPass.depth.use(0)
        r.debug.getUniform("alpha").set(false)
      of "edges":
        r.smaa.t_edge.use(0)
        r.debug.getUniform("alpha").set(false)
      of "brightpass":
        r.bloom.t_bright.use(0)
        r.debug.getUniform("alpha").set(false)
      of "occlusion":
        r.ssao.occlusion.use(0)
        r.debug.getUniform("alpha").set(false)
      else:
        discard
    Screen.quad.render()

  r.textRenderer.render(Screen.projection)
