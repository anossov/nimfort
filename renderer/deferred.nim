import logging
import config
import opengl
import gl/framebuffer
import gl/texture
import gl/shader
import math
import mesh
import vector
import systems/ecs
import systems/resources
import systems/camera
import systems/transform
import renderer/components
import renderer/shadowMap
import renderer/screen

type
  GeometryPass* = ref object
    fb: Framebuffer
    albedo*: Texture
    normal*: Texture
    position*: Texture
    shader: Program

  LightingPass* = ref object
    shaders: array[LightType, Program]
    emission: Program
    ball: Mesh

proc newGeometryPass*(): GeometryPass =
  var p, n, a: Texture
  var b = newFramebuffer()
  p = newTexture()
  p.image2d(nil, Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float, GL_RGBA16F)
  p.filter(false)

  n = newTexture()
  n.image2d(nil, Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float, GL_RGBA16F)
  n.filter(false)

  a = newTexture()
  a.image2d(nil, Screen.width, Screen.height, TextureFormat.RGBA, internalformat=GL_RGBA)
  a.filter(false)

  b.attach(p)
  b.attach(n)
  b.attach(a)
  b.attachDepthStencilRBO(Screen.width, Screen.height)

  debug("GBuffer: $1", b.check())

  var s = Resources.getShader("gbuffer")
  s.use()
  s.getUniform("albedo").set(0)
  s.getUniform("normal").set(1)
  s.getUniform("roughness").set(2)
  s.getUniform("metalness").set(3)
  s.getUniform("emission").set(4)

  return GeometryPass(
    fb: b,
    position: p,
    normal: n,
    albedo: a,
    shader: s,
  )


proc newLightingPass*(): LightingPass =
  let inc = ["dr_head", "brdfs"]
  var p = Resources.getShader("dr_point", fs_prepend=inc)
  var d = Resources.getShader("dr_directional", fs_prepend=inc)
  var a = Resources.getShader("dr_ambient", fs_prepend=inc)
  var s = Resources.getShader("dr_spot", fs_prepend=inc)
  var e = Resources.getShader("dr_emission")
  var shaders = [a, p, d, s]
  for shader in mitems(shaders):
    shader.use()
    shader.getUniform("gPosition").set(0)
    shader.getUniform("gNormalMetalness").set(1)
    shader.getUniform("gAlbedoRoughness").set(2)
    shader.getUniform("shadowMap").set(3)
    shader.getUniform("invBufferSize").set(Screen.pixelSize)
  e.use()
  e.getUniform("gPosition").set(0)
  e.getUniform("gAlbedoRoughness").set(2)
  e.getUniform("invBufferSize").set(Screen.pixelSize)

  return LightingPass(
    shaders: shaders,
    emission: e,
    ball: Resources.getMesh("lightball"),
  )


proc perform*(pass: var GeometryPass) =
  pass.fb.use(FramebufferTarget.Both)
  glEnable(GL_DEPTH_TEST)
  glDepthMask(true)
  glDisable(GL_BLEND)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, Screen.width, Screen.height)

  pass.shader.use()
  pass.shader.getUniform("view").set(Camera.getView())
  pass.shader.getUniform("projection").set(Camera.getProjection())

  for i in ModelStore().data:
    var model = i.entity.transform.matrix
    pass.shader.getUniform("model").set(model)
    pass.shader.getUniform("emissionIntensity").set(i.emissionIntensity)
    for i, t in pairs(i.textures):
      t.use(i)
    i.mesh.render()

proc perform*(pass: var LightingPass, gp: var GeometryPass, output: var Framebuffer) =
  gp.fb.use(FramebufferTarget.Read)
  output.use(FramebufferTarget.Draw)
  glBlitFramebuffer(0, 0, Screen.width, Screen.height,
                    0, 0, Screen.width, Screen.height,
                    GL_DEPTH_BUFFER_BIT, GL_NEAREST)
  output.use(FramebufferTarget.Both)

  glViewport(0, 0, Screen.width, Screen.height)
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

    for light in LightStore().data:
      if light.kind != kind:
        continue

      if light.entity.has("Transform"):
        let t = light.entity.transform

        shader.getUniform("lightPos").set(t.position)
        shader.getUniform("lightDir").set(t.forward)
        shader.getUniform("lightSpace").set(light.getProjection() * t.getView())
        shader.getUniform("hasShadowmap").set(not light.shadowMap.isEmpty())

        case light.kind:
        of Point:
          shader.getUniform("radius").set(light.radius)
          shader.getUniform("transform").set(Camera.getProjection() * Camera.getView() * translate(t.position) * scale(light.radius))
        of Spot:
          shader.getUniform("transform").set(identity())
          shader.getUniform("cosSpotAngle").set(cos(light.spotAngle.radians))
          shader.getUniform("cosSpotFalloff").set(cos(light.spotFalloff.radians))
        else:
          shader.getUniform("transform").set(identity())

      shader.getUniform("lightColor").set(light.color)

      light.shadowMap.use(3)

      case light.kind:
      of Point:
        pass.ball.render()
      else:
        Screen.quad.render()

  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
  pass.emission.use()
  pass.emission.getUniform("transform").set(identity())
  Screen.quad.render()
