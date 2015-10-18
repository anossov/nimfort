import logging
import systems/resources
import gl/framebuffer
import gl/shader
import gl/texture
import mesh
import config
import opengl

type
  Tonemapping* = ref object
    fb*: Framebuffer
    hdr: Texture
    shader: Program
    quad: Mesh

proc newTonemapping*(): Tonemapping = 
  var fb = newFramebuffer()
  var t = newTexture()

  t.image2d(nil, windowWidth, windowHeight, false, TextureFormat.RGB, PixelType.Float, GL_RGB16F)
  t.filter(false)

  fb.attach(t)
  fb.attachDepthStencilRBO(windowWidth, windowHeight)

  debug("HDR buffer: $1", fb.check())
  
  var tm = Resources.getShader("tonemap")
  tm.use()
  tm.getUniform("hdr").set(0)

  var quad = newMesh()
  quad.vertices = @[
    Vertex(position: [-1.0'f32,  1.0, 0.0]),
    Vertex(position: [-1.0'f32, -1.0, 0.0]),
    Vertex(position: [ 1.0'f32,  1.0, 0.0]),
    Vertex(position: [ 1.0'f32, -1.0, 0.0]),
  ]
  quad.indices = @[0'u32, 1, 2, 2, 1, 3]
  quad.buildBuffers()

  return Tonemapping(
    fb: fb,
    hdr: t,
    shader: tm,
    quad: quad,
  )

proc perform*(pass: Tonemapping) =
  useDefaultFramebuffer(FramebufferTarget.Both)
  glClear(GL_COLOR_BUFFER_BIT)
  glDisable(GL_DEPTH_TEST)
  pass.shader.use()
  pass.hdr.use(0)
  pass.quad.render()