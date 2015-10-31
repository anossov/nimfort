import logging
import systems/resources
import systems/messaging
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
    listener: Listener
    exposure: float


  Bloom* = ref object
    size: ivec2
    fb_in*: Framebuffer
    fb_bright: Framebuffer
    t_in: Texture
    t_bright*: Texture
    fb_pp: array[2, Framebuffer]
    t_pp: array[2, Texture]
    s_brightpass: Program
    s_hblur: Program
    s_vblur: Program
    s_finalize: Program


proc newTonemapping*(): Tonemapping =
  var fb = newFramebuffer()
  var t = newTexture2d(Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float)
  fb.attach(t)
  fb.attachDepthStencilRBO(Screen.width, Screen.height)

  debug("HDR buffer: ", fb.check())

  var tm = getShader("tonemap")
  tm.use()
  tm.getUniform("hdr").set(0)

  var listener = newListener()
  listener.listen("camera")

  return Tonemapping(
    fb_in: fb,
    hdr: t,
    shader: tm,
    listener: listener,
    exposure: 5,
  )

proc perform*(pass: var Tonemapping, fb_out: var Framebuffer) =
  for m in pass.listener.getMessages():
    case m.name:
      of "exposure-up": pass.exposure += 1.0
      of "exposure-down": pass.exposure -= 1.0
      else: discard
  if pass.exposure < 1.0:
    pass.exposure = 1.0

  glViewport(0, 0, Screen.width, Screen.height)
  fb_out.use(FramebufferTarget.Both)
  glClear(GL_COLOR_BUFFER_BIT)
  glDisable(GL_DEPTH_TEST)
  pass.shader.use()
  pass.shader.getUniform("exposure").set(pass.exposure)
  pass.hdr.use(0)
  Screen.quad.render()


proc newBloom*(): Bloom =
  var fb_in = newFramebuffer()
  var t_in = newTexture2d(Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float)

  fb_in.attach(t_in)
  fb_in.attachDepthStencilRBO(Screen.width, Screen.height)

  let
    size = ivec(Screen.width shr bloomScale, Screen.height shr bloomScale)
    invsize = size.toFloat.inverse()

  var fb_bright = newFramebuffer()
  var t_bright = newTexture2d(Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float)
  fb_bright.attach(t_bright)

  var fb_pingpong = [newFramebuffer(), newFramebuffer()]
  var t_pingpong = [
    newTexture2d(size.x, size.y, TextureFormat.RGB, PixelType.Float),
    newTexture2d(size.x, size.y, TextureFormat.RGB, PixelType.Float),
  ]
  for i in 0..1:
    fb_pingpong[i].use()
    fb_pingpong[i].attach(t_pingpong[i])


  var s_brightpass = getShader("brightpass")
  s_brightpass.use()
  s_brightpass.getUniform("threshold").set(bloomThreshold)


  var s_hblur = getShader("gaussian_h")
  s_hblur.use()
  s_hblur.getUniform("pixelSize").set(invsize)
  s_hblur.getUniform("level").set(bloomScale)

  var s_vblur = getShader("gaussian_v")
  s_vblur.use()
  s_vblur.getUniform("pixelSize").set(invsize)
  s_vblur.getUniform("level").set(bloomScale)

  var s_finalize = getShader("bloom")
  s_finalize.use()
  s_finalize.getUniform("color").set(0)
  s_finalize.getUniform("bloom").set(1)

  return Bloom(
    size: size,
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
  glViewport(0, 0, Screen.width, Screen.height)
  pass.fb_bright.use()
  glClear(GL_COLOR_BUFFER_BIT)
  glDisable(GL_DEPTH_TEST)

  pass.t_in.use(0)
  pass.s_brightpass.use()
  Screen.quad.render()

  pass.t_bright.use(0)
  pass.t_in.generateMipmap()
  pass.t_in.filter(true)

  glViewport(0, 0, pass.size.x, pass.size.y)
  for i in 0..(2*bloomPasses + 1):
    if i == 0:
      pass.s_hblur.use()
    if i == (bloomPasses + 1):
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
