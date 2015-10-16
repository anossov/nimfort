import logging
import config
import opengl
import gl/framebuffer
import gl/texture
import gl/shader
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

  let quad = MeshData(
    vertices: @[
      Vertex(position: [-1.0'f32,  1.0, 0.0], uv: [0.0'f32, 1.0]),
      Vertex(position: [-1.0'f32, -1.0, 0.0], uv: [0.0'f32, 0.0]),
      Vertex(position: [ 1.0'f32,  1.0, 0.0], uv: [1.0'f32, 1.0]),
      Vertex(position: [ 1.0'f32, -1.0, 0.0], uv: [1.0'f32, 0.0]),
    ],
    indices: @[0'u32, 2, 1, 2, 3, 1]
  )

  return LightingPass(
    shader: s,
    quad: newMesh(quad, emptyTexture())
  )


proc perform*(pass: var GeometryPass, geometry: seq[Renderable3d]) =
  pass.fb.use()
  glEnable(GL_DEPTH_TEST)
  glDisable(GL_BLEND)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, windowWidth, windowHeight)

  pass.shader.use()
  pass.shader.getUniform("view").set(Camera.getView())
  pass.shader.getUniform("projection").set(Camera.getProjection())
  
  for i in geometry:
    var model = i.transform.matrix
    pass.shader.getUniform("model").set(model)
    i.mesh.texture.use(0)
    i.mesh.normalmap.use(1)
    i.mesh.specularmap.use(2)
    i.mesh.render()


proc begin*(pass: var LightingPass) =
  useDefaultFramebuffer()
  glViewport(0, 0, windowWidth, windowHeight)
  glEnable(GL_BLEND)
  glBlendEquation(GL_FUNC_ADD)
  glBlendFunc(GL_ONE, GL_ONE)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  glDisable(GL_DEPTH_TEST)

  pass.shader.use()
  pass.shader.getUniform("eye").set(Camera.position)

proc perform*(pass: var LightingPass, light: Light, gp: GeometryPass) =
  var lp = vec(light.position.x, light.position.y, light.position.z, 0.0)
  if light.kind == Point:
    lp.w = 1.0
  pass.shader.getUniform("light").set(lp)
  pass.shader.getUniform("lightspace").set(light.getProjection() * light.getView())
  pass.shader.getUniform("hasShadowmap").set(not light.shadowMap.isEmpty())
  pass.shader.getUniform("att").set(light.attenuation)

  gp.position.use(0)
  gp.normal.use(1)
  gp.albedo.use(2)
  light.shadowMap.use(3)

  pass.quad.render()