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
import engine/transform

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
    shadowMaps: ShadowMap
    geometryPass: GeometryPass
    lightingPass: LightingPass
    textRenderer: TextRenderer
    bloom: Bloom
    tonemapping: Tonemapping
    smaa: SMAA
    ssao: SSAO
    listener: Listener
    debug: Program
    overlay: Program

    fb1: Framebuffer
    fb2: Framebuffer
    color1: Texture
    color2: Texture
    depth: Texture

    debugMode: string


var Renderer*: RenderSystem


proc initRenderSystem*() =
  loadExtensions()
  initScreen()

  Renderer = RenderSystem(
    geometryPass: newGeometryPass(),
    lightingPass: newLightingPass(),
    shadowMaps: newShadowMap(),
    textRenderer: newTextRenderer(),
    bloom: newBloom(),
    tonemapping: newTonemapping(),
    smaa: newSMAA(),
    ssao: newSSAO(),
    debug: getShader("debug"),
    overlay: getShader("overlay"),
    debugmode: "",

    fb1: newFramebuffer(),
    fb2: newFramebuffer(),
    color1: newTexture2d(Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float),
    color2: newTexture2d(Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float),
  )

  Renderer.depth = Renderer.geometryPass.depth
  Renderer.fb1.use()
  Renderer.fb1.attach(Renderer.color1)
  Renderer.fb1.attach(Renderer.depth, depth=true)

  Renderer.fb2.use()
  Renderer.fb2.attach(Renderer.color2)
  Renderer.fb2.attach(Renderer.depth, depth=true)

  glClearColor(0.0, 0.0, 0.0, 0.0)
  glEnable(GL_CULL_FACE)
  glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS)

  Renderer.listener = newListener()
  Renderer.listener.listen("debug")

  info("Renderer ok: OpenGL v.", cast[cstring](glGetString(GL_VERSION)))


# TODO: maybe Tile-Based DR
# HBAO
# Hi-Z Screen-Space Cone-Traced Reflections

proc renderOverlays*(r: RenderSystem, fb_out: var Framebuffer) =
  fb_out.use()
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  r.overlay.use()
  r.overlay.getUniform("view").set(Camera.view)
  r.overlay.getUniform("projection").set(Camera.projection)
  for i in OverlayStore().data:
    r.overlay.getUniform("model").set(i.entity.transform.matrix)
    r.overlay.getUniform("color").set(i.color)
    i.mesh.render()

proc renderDebug*(r: RenderSystem) =
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

proc render*() =
  meshesRendered = 0

  var r = Renderer

  for m in r.listener.getMessages():
    if r.debugmode == m.name:
      r.debugmode = ""
    else:
      r.debugmode = m.name

  if r.debugmode == "wire":
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
  else:
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)

  r.geometryPass.fillGBuffer()
  r.shadowMaps.renderShadowMaps()
  r.ssao.perform(r.geometryPass.depth, r.geometryPass.normal)
  r.lightingPass.doLighting(r.geometryPass, r.ssao.occlusion, r.fb1)
  r.bloom.perform(r.color1, r.fb2)
  r.tonemapping.perform(r.color2, r.fb1)
  r.renderOverlays(r.fb1)
  r.smaa.perform(r.color1, defaultFramebuffer)
  r.renderDebug()
  r.textRenderer.render(Screen.projection)
