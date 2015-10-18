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
  GeometryPass* = ref object
    fb: Framebuffer
    albedo*: Texture
    normal*: Texture
    position*: Texture
    shader: Program

  LightingPass* = ref object
    shaders: array[LightType, Program]
    quad: Mesh
    ball: Mesh

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
  b.attachDepthStencilRBO(windowWidth, windowHeight)

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
  var p = Resources.getShader("dr_point")
  var d = Resources.getShader("dr_directional")
  var a = Resources.getShader("dr_ambient")
  var s = Resources.getShader("dr_spot")
  var shaders = [a, p, d, s]
  for shader in mitems(shaders):
    shader.use()
    shader.getUniform("gPosition").set(0)
    shader.getUniform("gNormal").set(1)
    shader.getUniform("gAlbedoSpec").set(2)
    shader.getUniform("shadowMap").set(3)

  var quad = newMesh()
  quad.vertices = @[
    Vertex(position: [-1.0'f32,  1.0, 0.0]),
    Vertex(position: [-1.0'f32, -1.0, 0.0]),
    Vertex(position: [ 1.0'f32,  1.0, 0.0]),
    Vertex(position: [ 1.0'f32, -1.0, 0.0]),
  ]
  quad.indices = @[0'u32, 1, 2, 2, 1, 3]
  quad.buildBuffers()

  return LightingPass(
    shaders: shaders,
    quad: quad,
    ball: Resources.getMesh("lightball"),
  )


proc perform*(pass: var GeometryPass, geometry: seq[Model]) =
  pass.fb.use(FramebufferTarget.Both)
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

proc perform*(pass: var LightingPass, lights: seq[Light], gp: var GeometryPass, output: var Framebuffer) =
  gp.fb.use(FramebufferTarget.Read)
  output.use(FramebufferTarget.Draw)
  glBlitFramebuffer(0, 0, windowWidth, windowHeight, 0, 0, windowWidth, windowHeight, GL_DEPTH_BUFFER_BIT, GL_NEAREST);
  output.use(FramebufferTarget.Both)
  
  glViewport(0, 0, windowWidth, windowHeight)
  glEnable(GL_BLEND)
  glBlendEquation(GL_FUNC_ADD)
  glBlendFunc(GL_ONE, GL_ONE)
  glClear(GL_COLOR_BUFFER_BIT)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  glEnable(GL_DEPTH_TEST)
  glDepthMask(false)

  gp.position.use(0)
  gp.normal.use(1)
  gp.albedo.use(2)

  for kind, shader in mpairs(pass.shaders):
    shader.use()
    shader.getUniform("eye").set(Camera.position)

    for light in lights:
      if light.kind != kind:
        continue

      shader.getUniform("invBufferSize").set(vec(1.0 / windowWidth, 1.0 / windowHeight))
      shader.getUniform("light").set(light.position)
      shader.getUniform("lightDir").set(light.target - light.position)
      shader.getUniform("lightspace").set(light.getProjection() * light.getView())
      shader.getUniform("hasShadowmap").set(not light.shadowMap.isEmpty())
      shader.getUniform("radius").set(light.radius)
      shader.getUniform("lightColor").set(light.color)
      shader.getUniform("cosSpotAngle").set(cos(light.spotAngle.radians))
      shader.getUniform("cosSpotFalloff").set(cos(light.spotFalloff.radians))
      
      light.shadowMap.use(3)

      case light.kind:
      of Point:
        shader.getUniform("transform").set(Camera.getProjection() * Camera.getView() * translate(light.position) * scale(light.radius))
        pass.ball.render()
      else:
        shader.getUniform("transform").set(identity())
        pass.quad.render()