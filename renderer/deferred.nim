import logging
import config
import opengl
import gl/framebuffer
import gl/texture
import gl/shader
import math
import mesh
import vector
import systems/resources
import systems/camera
import renderer/components
import renderer/shadowMap

type
  GeometryPass* = object
    fb: Framebuffer
    albedo*: Texture
    normal*: Texture
    position*: Texture

    shader: Program

  LightingPass* = object
    shader: Program
    quad: Mesh
    octagon: Mesh


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

  return GeometryPass(
    fb: b,
    position: p,
    normal: n,
    albedo: a,
    shader: s,
  )


proc newLightingPass*(): LightingPass =
  var s = Resources.getShader("main")
  s.use()
  s.getUniform("gPosition").set(0)
  s.getUniform("gNormal").set(1)
  s.getUniform("gAlbedoSpec").set(2)
  s.getUniform("shadowMap").set(3)

  var quad = newMesh()
  quad.vertices = @[
    Vertex(position: [-1.0'f32,  1.0, 0.0]),
    Vertex(position: [-1.0'f32, -1.0, 0.0]),
    Vertex(position: [ 1.0'f32,  1.0, 0.0]),
    Vertex(position: [ 1.0'f32, -1.0, 0.0]),
  ]
  quad.indices = @[0'u32, 2, 1, 2, 3, 1]
  quad.buildBuffers()

  var octagon = newMesh()
  let hs: float32 = 1.0 / (1.0 + sqrt(2.0))
  octagon.vertices = @[
    Vertex(position: [ -hs,    -1.0, 0.0]),
    Vertex(position: [  hs,    -1.0, 0.0]),
    Vertex(position: [ 1.0'f32, -hs, 0.0]),
    Vertex(position: [ 1.0'f32,  hs, 0.0]),
    Vertex(position: [  hs,     1.0, 0.0]),
    Vertex(position: [ -hs,     1.0, 0.0]),
    Vertex(position: [-1.0'f32,  hs, 0.0]),
    Vertex(position: [-1.0'f32, -hs, 0.0]),
  ]
  octagon.indices = @[0'u32, 2, 1, 0, 7, 2, 7, 3, 2, 7, 6, 3, 6, 4, 3, 6, 5, 4]
  octagon.buildBuffers()
  return LightingPass(
    shader: s,
    quad: quad,
    octagon: octagon,
  )


proc perform*(pass: var GeometryPass, geometry: seq[Model]) =
  pass.fb.use()
  glEnable(GL_DEPTH_TEST)
  glDepthMask(true)
  glDisable(GL_BLEND)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, windowWidth, windowHeight)

  pass.shader.use()
  pass.shader.getUniform("view").set(Camera.getView())
  pass.shader.getUniform("projection").set(Camera.getProjection())
  
  for i in geometry:
    var model = i.transform.matrix
    pass.shader.getUniform("model").set(model)
    for i, t in pairs(i.textures):
      t.use(i)
    i.mesh.render()

proc perform*(pass: var LightingPass, lights: seq[Light], gp: GeometryPass) =
  useDefaultFramebuffer()
  glViewport(0, 0, windowWidth, windowHeight)
  glEnable(GL_BLEND)
  glBlendEquation(GL_FUNC_ADD)
  glBlendFunc(GL_ONE, GL_ONE)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  glDisable(GL_DEPTH_TEST)
  glDepthMask(false)

  pass.shader.use()
  pass.shader.getUniform("eye").set(Camera.position)

  gp.position.use(0)
  gp.normal.use(1)
  gp.albedo.use(2)

  for light in lights:
    var lp = vec(light.position.x, light.position.y, light.position.z, (light.kind == Point).float32)
    
    pass.shader.getUniform("transform").set(light.getScreenExtentsTransform())

    pass.shader.getUniform("light").set(lp)
    pass.shader.getUniform("lightspace").set(light.getProjection() * light.getView())
    pass.shader.getUniform("hasShadowmap").set(not light.shadowMap.isEmpty())
    pass.shader.getUniform("radius").set(light.radius)
    
    light.shadowMap.use(3)

    case light.kind:
    of Point:
      pass.octagon.render()
    else:
      pass.quad.render()