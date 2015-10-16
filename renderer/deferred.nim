import logging
import config
import systems/resources
import rendering/components

type
  GeometryPass = object
    fb: Framebuffer
    albedo: Texture
    normal: Texture
    position: Texture

    shader: Program


proc newGeometryPass*(): GeometryPass =
  let 
    w = windowWidth.int32
    h = windowHeight.int32
  var p, n, a: Texture
  var b = newFramebuffer()
  p = newTexture()
  p.image2d(nil, w, h, false, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  p.filter(false)
  
  n = newTexture()
  n.image2d(nil, w, h, false, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  n.filter(false)
  
  a = newTexture()
  a.image2d(nil, w, h, false, TextureFormat.RGBA, internalformat=GL_RGBA)
  a.filter(false)

  b.attach(p)
  b.attach(n)
  b.attach(a)
  b.attachDepthStencilRBO(w, h)

  debug("GBuffer: $1", b.check())

  var s = Resources.getShader("gbuffer")
  s.use()
  s.getUniform("normalmap").set(1)
  s.getUniform("specularmap").set(2)

  return GBuffer(
    fb: b,
    position: p,
    normal: n,
    albedo: a,
    shader: s,
  )


proc perform*(pass: GeometryPass, view: mat4, proj: mat4, geometry: seq[Renderable3d]) =
  pass.buffer.use()
  glEnable(GL_DEPTH_TEST)
  glDisable(GL_BLEND)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, windowWidth, windowHeight)

  pass.shader.use()
  pass.shader.getUniform("view").set(view)
  pass.shader.getUniform("projection").set(proj)
  
  for i in geometry:
    var model = i.transform.matrix
    r.shaderG.getUniform("model").set(model)
    i.mesh.texture.use(0)
    i.mesh.normalmap.use(1)
    i.mesh.specularmap.use(2)
    i.mesh.render()