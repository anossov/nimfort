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
    skybox: Program
    IBL: Program
    ambient: Program

proc newGeometryPass*(): GeometryPass =
  var p, n, a: Texture
  var b = newFramebuffer()
  p = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float, false)
  n = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float, false)
  a = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Ubyte, false)

  b.attach(p)
  b.attach(n)
  b.attach(a)
  b.attachDepthStencilRBO(Screen.width, Screen.height)

  debug("GBuffer: ", b.check())

  var s = getShader("gbuffer")
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
  var p = getShader("dr_point", fs_prepend=inc)
  var d = getShader("dr_directional", fs_prepend=inc)
  var s = getShader("dr_spot", fs_prepend=inc)
  var e = getShader("dr_emission")

  var s_ibl = getShader("dr_ibl", fs_prepend=inc)
  var s_amb = getShader("dr_ambient", fs_prepend=inc)

  var lightshaders = [p, d, s]

  var shaders = [p, d, s, e, s_ibl, s_amb];
  for shader in mitems(shaders):
    shader.use()
    shader.getUniform("gPosition").set(0)
    shader.getUniform("gNormalMetalness").set(1)
    shader.getUniform("gAlbedoRoughness").set(2)
    shader.getUniform("shadowMap").set(3)
    shader.getUniform("invBufferSize").set(Screen.pixelSize)

  s_ibl.use()
  s_ibl.getUniform("cubemap").set(3)

  return LightingPass(
    shaders: lightshaders,
    emission: e,
    ball: getMesh("lightball"),
    skybox: getShader("skybox"),
    IBL: s_ibl,
    ambient: s_amb,
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

  let PV = Camera.getProjection() * Camera.getView();

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
          shader.getUniform("transform").set(PV * translate(t.position) * scale(light.radius))
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

  for i in GhettoIBLStore().data:
    pass.IBL.use()
    pass.IBL.getUniform("eye").set(Camera.position)
    pass.IBL.getUniform("lightColor").set(i.color)
    i.cubemap.use(3)
    Screen.quad.render()

  for i in AmbientCubeStore().data:
    pass.ambient.use()
    pass.ambient.getUniform("eye").set(Camera.position)
    pass.ambient.getUniform("colors[0]").set(i.colors[0])
    pass.ambient.getUniform("colors[1]").set(i.colors[1])
    pass.ambient.getUniform("colors[2]").set(i.colors[2])
    pass.ambient.getUniform("colors[3]").set(i.colors[3])
    pass.ambient.getUniform("colors[4]").set(i.colors[4])
    pass.ambient.getUniform("colors[5]").set(i.colors[5])
    Screen.quad.render()

  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
  pass.emission.use()
  pass.emission.getUniform("transform").set(identity())
  Screen.quad.render()

  glDepthFunc(GL_EQUAL)
  for sb in SkyboxStore().data:
    pass.skybox.use()
    pass.skybox.getUniform("projection").set(Camera.getProjection())
    pass.skybox.getUniform("view").set(Camera.getView())
    pass.skybox.getUniform("intensity").set(sb.intensity)
    sb.cubemap.use(3)
    Screen.quad.render()
  glDepthFunc(GL_LESS)
