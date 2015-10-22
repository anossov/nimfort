import logging
import systems/resources
import gl/framebuffer
import gl/shader
import gl/texture
import mesh
import config
import opengl
import vector
import renderer/screen

type
  Tonemapping* = ref object
    fb_in*: Framebuffer
    hdr: Texture
    shader: Program

  Bloom* = ref object
    fb_in*: Framebuffer
    fb_bright: Framebuffer
    t_in: Texture
    t_bright: Texture
    fb_pp: array[2, Framebuffer]
    t_pp: array[2, Texture]
    s_brightpass: Program
    s_hblur: Program
    s_vblur: Program
    s_finalize: Program


proc newTonemapping*(): Tonemapping =
  var fb = newFramebuffer()
  var t = newTexture()

  t.image2d(nil, Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  t.filter(true)

  fb.attach(t)
  fb.attachDepthStencilRBO(Screen.width, Screen.height)

  debug("HDR buffer: $1", fb.check())

  var tm = Resources.getShader("tonemap")
  tm.use()
  tm.getUniform("hdr").set(0)

  return Tonemapping(
    fb_in: fb,
    hdr: t,
    shader: tm,
  )

proc perform*(pass: Tonemapping, fb_out: var Framebuffer) =
  glViewport(0, 0, Screen.width, Screen.height)
  fb_out.use(FramebufferTarget.Both)
  glClear(GL_COLOR_BUFFER_BIT)
  glDisable(GL_DEPTH_TEST)
  pass.shader.use()
  pass.hdr.use(0)
  Screen.quad.render()


proc newBloom*(): Bloom =
  var fb_in = newFramebuffer()
  var t_in = newTexture()
  t_in.image2d(nil, Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  t_in.filter(true)
  t_in.clamp()

  fb_in.attach(t_in)

  let size = 1024'i32

  var fb_bright = newFramebuffer()
  var t_bright = newTexture()
  t_bright.image2d(nil, Screen.width shr 1, Screen.height shr 1, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  t_bright.filter(true)
  t_bright.clamp()

  fb_bright.attach(t_bright)

  var fb_pingpong = [newFramebuffer(), newFramebuffer()]
  var t_pingpong = [newTexture(), newTexture()]
  for i in 0..1:
    fb_pingpong[i].use()
    t_pingpong[i].use(0)
    t_pingpong[i].image2d(nil, Screen.width shr 1, Screen.height shr 1, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
    t_pingpong[i].clamp()
    t_pingpong[i].filter(true)
    fb_pingpong[i].attach(t_pingpong[i])


  var s_brightpass = Resources.getShader("brightpass")
  s_brightpass.use()
  s_brightpass.getUniform("threshold").set(15.0)

  var s_hblur = Resources.getShader("gaussian_h")
  s_hblur.use()
  s_hblur.getUniform("pixelSize").set(vec(2.0/windowWidth, 2.0/windowHeight))
  var s_vblur = Resources.getShader("gaussian_v")
  s_vblur.use()
  s_vblur.getUniform("pixelSize").set(vec(2.0/windowWidth, 2.0/windowHeight))

  var s_finalize = Resources.getShader("bloom")
  s_finalize.use()
  s_finalize.getUniform("color").set(0)
  s_finalize.getUniform("bloom").set(1)

  return Bloom(
    fb_in: fb_in,
    fb_bright: fb_bright,
    t_in: t_in,
    t_bright: t_bright,
    fb_pp: fb_pingpong,
    t_pp: t_pingpong,
    s_brightpass: s_brightpass,
    s_hblur: s_hblur,
    s_vblur: s_vblur,
    s_finalize: s_finalize,
  )

proc perform*(pass: Bloom, fb_out: var Framebuffer) =
  glViewport(0, 0, Screen.width shr 1, Screen.height shr 1)
  pass.fb_bright.use()
  glClear(GL_COLOR_BUFFER_BIT)
  glDisable(GL_DEPTH_TEST)

  pass.t_in.use(0)
  pass.s_brightpass.use()
  Screen.quad.render()

  pass.t_bright.use(0)
  for i in 0..5:
    if i == 0:
      pass.s_hblur.use()
    if i == 3:
      pass.s_vblur.use()

    if i > 0:
      pass.t_pp[1 - i mod 2].use(0)

    pass.fb_pp[i mod 2].use()
    Screen.quad.render()

  fb_out.use()
  glViewport(0, 0, Screen.width, Screen.height)
  glClear(GL_COLOR_BUFFER_BIT)

  pass.s_finalize.use()
  pass.t_in.use(0)
  pass.t_pp[1].use(1)
  Screen.quad.render()