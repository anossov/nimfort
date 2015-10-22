import logging
import opengl
import config
import systems/resources
import gl/texture
import gl/framebuffer
import gl/shader
import mesh
import vector
import renderer/screen

const
  AREATEX_WIDTH    = 160
  AREATEX_HEIGHT   = 560
  SEARCHTEX_WIDTH  = 64
  SEARCHTEX_HEIGHT = 16

type
  SMAA* = ref object
    fb_in*: Framebuffer
    fb_blend: Framebuffer
    fb_edge: Framebuffer
    s_edge: Program
    s_blend: Program
    s_nh: Program
    debug: Program
    t_in: Texture
    t_edge: Texture
    t_blend: Texture
    t_area: Texture
    t_search: Texture

proc newSMAA*(): SMAA =
  var in_tex = newTexture2d(Screen.width, Screen.height, TextureFormat.RGB, PixelType.Float)
  var in_fbo = newFramebuffer()
  in_fbo.attach(in_tex)
  debug("SMAA input: $1", in_fbo.check())

  var edge_tex = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float)
  var blend_tex = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float)

  var smaa_area = readFile("assets/textures/smaa_area.raw")
  var area_tex = newTexture()
  area_tex.image2d(GL_RG8, AREATEX_WIDTH, AREATEX_HEIGHT, TextureFormat.RG, PixelType.Ubyte, smaa_area)
  area_tex.filter(true)
  area_tex.clamp()

  var smaa_search = readFile("assets/textures/smaa_search.raw")
  var search_tex = newTexture()
  search_tex.image2d(GL_RED, SEARCHTEX_WIDTH, SEARCHTEX_HEIGHT, TextureFormat.Red, PixelType.Ubyte, smaa_search)
  search_tex.filter(false)
  search_tex.clamp()

  var stencil = newTexture2d(Screen.width, Screen.height, TextureFormat.DepthStencil, PixelType.Uint24_8, false)


  var edge_fbo = newFramebuffer()
  edge_fbo.attach(edge_tex)
  edge_fbo.attach(stencil, depth=true, stencil=true)

  var blend_fbo = newFramebuffer()
  blend_fbo.attach(blend_tex)
  blend_fbo.attach(stencil, depth=true, stencil=true)


  var edge_shader = Resources.getShader("smaa_edge", ["smaa_head"], ["smaa_head"])
  edge_shader.use()
  edge_shader.getUniform("albedo_tex").set(0)
  edge_shader.getUniform("SMAA_RT_METRICS").set(vec(Screen.pixelSize.x, Screen.pixelSize.y, Screen.size.x, Screen.size.y))

  var blend_shader = Resources.getShader("smaa_blend", ["smaa_head"], ["smaa_head"])
  blend_shader.use()
  blend_shader.getUniform("edge_tex").set(0)
  blend_shader.getUniform("area_tex").set(1)
  blend_shader.getUniform("search_tex").set(2)
  blend_shader.getUniform("SMAA_RT_METRICS").set(vec(Screen.pixelSize.x, Screen.pixelSize.y, Screen.size.x, Screen.size.y))

  var nh_shader = Resources.getShader("smaa_neighborhood", ["smaa_head"], ["smaa_head"])
  nh_shader.use()
  nh_shader.getUniform("albedo_tex").set(0)
  nh_shader.getUniform("blend_tex").set(1)
  nh_shader.getUniform("albedo_tex2").set(2)
  nh_shader.getUniform("SMAA_RT_METRICS").set(vec(Screen.pixelSize.x, Screen.pixelSize.y, Screen.size.x, Screen.size.y))

  var debug = Resources.getShader("debug")

  return SMAA(
    fb_edge: edge_fbo,
    fb_blend: blend_fbo,
    fb_in: in_fbo,
    s_edge: edge_shader,
    s_blend: blend_shader,
    s_nh: nh_shader,
    t_edge: edge_tex,
    t_blend: blend_tex,
    t_area: area_tex,
    t_search: search_tex,
    t_in: in_tex,
    debug: debug,
  )


proc perform*(pass: SMAA, fb_out: var Framebuffer) =
  pass.fb_edge.use()

  glViewport(0, 0, Screen.width, Screen.height)
  glDisable(GL_DEPTH_TEST)
  glDisable(GL_BLEND)
  glEnable(GL_STENCIL_TEST)
  glStencilMask(0xFF)
  glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
  glStencilFunc(GL_ALWAYS, 1, 0xFF)

  pass.s_edge.use()
  pass.t_in.use(0)

  Screen.quad.render()

  pass.fb_blend.use()

  glStencilFunc(GL_EQUAL, 1, 0xFF)
  glStencilMask(0x00)

  glClear(GL_COLOR_BUFFER_BIT)

  pass.s_blend.use()
  pass.t_edge.use(0)
  pass.t_area.use(1)
  pass.t_search.use(2)

  Screen.quad.render()

  fb_out.use()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  glDisable(GL_STENCIL_TEST)

  pass.s_nh.use()
  pass.t_in.use(0)
  pass.t_blend.use(1)

  Screen.quad.render()
