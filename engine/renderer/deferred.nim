import logging
import opengl
import math

import config

import gl/framebuffer
import gl/texture
import gl/shader

import engine/mesh
import engine/vector
import engine/ecs
import engine/resources
import engine/camera
import engine/transform
import engine/renderer/components
import engine/renderer/shadowMap
import engine/renderer/screen
import engine/geometry/aabb

type
  GeometryPass* = ref object
    fb: Framebuffer
    albedo*: Texture
    normal*: Texture
    depth*: Texture
    shader: Program

  LightingPass* = ref object
    shaders: array[LightType, Program]
    emission: Program
    ball: Mesh
    skybox: Program
    IBL: Program
    ambient: Program
    overlay: Program

proc newGeometryPass*(): GeometryPass =
  var n, a, d: Texture
  var b = newFramebuffer()

  n = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Float, false)
  a = newTexture2d(Screen.width, Screen.height, TextureFormat.RGBA, PixelType.Ubyte, false)
  d = newTexture2d(Screen.width, Screen.height, TextureFormat.DepthStencil, PixelType.Uint24_8, false)

  b.attach(n)
  b.attach(a)
  b.attach(d, depth=true, stencil=true)

  debug("GBuffer: ", b.check())

  var s = getShader("gbuffer")
  s.use()
  s.getUniform("albedo").set(0)
  s.getUniform("normal").set(1)
  s.getUniform("roughness").set(2)
  s.getUniform("metalness").set(3)

  return GeometryPass(
    fb: b,
    normal: n,
    albedo: a,
    depth: d,
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

  var shaders = [p, d, s, s_ibl, s_amb];
  for shader in mitems(shaders):
    shader.use()
    shader.getUniform("gNormalMetalness").set(0)
    shader.getUniform("gAlbedoRoughness").set(1)
    shader.getUniform("gDepth").set(2)
    shader.getUniform("shadowMap").set(3)
    shader.getUniform("shadowMapCube").set(3)
    shader.getUniform("invBufferSize").set(Screen.pixelSize)

  s_ibl.use()
  s_ibl.getUniform("cubemap").set(4)

  e.use()
  e.getUniform("albedo").set(0)
  e.getUniform("emission").set(1)

  s_amb.use()
  s_amb.getUniform("AO").set(5)

  return LightingPass(
    shaders: lightshaders,
    emission: e,
    ball: getMesh("lightball"),
    skybox: getShader("skybox"),
    IBL: s_ibl,
    ambient: s_amb,
    overlay: getShader("overlay"),
  )


proc fillGBuffer*(pass: var GeometryPass) =
  pass.fb.use(FramebufferTarget.Both)
  glEnable(GL_DEPTH_TEST)
  glDepthMask(true)
  glDisable(GL_BLEND)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, Screen.width, Screen.height)

  pass.shader.use()
  pass.shader.getUniform("view").set(Camera.view)
  pass.shader.getUniform("projection").set(Camera.projection)

  for i in ModelStore().data:
    if i.emissionOnly: continue
    var model = i.entity.transform.matrix
    let bb = newAABB(model * i.bb.min, model * i.bb.max)
    if bb.outside(Camera.boundingBox): continue

    pass.shader.getUniform("model").set(model)
    for i, t in pairs(i.textures):
      t.use(i)
    i.mesh.render()


proc renderSkybox(pass: LightingPass) =
  glDepthFunc(GL_EQUAL)
  for sb in SkyboxStore().data:
    pass.skybox.use()
    pass.skybox.getUniform("projection").set(Camera.projection)
    pass.skybox.getUniform("view").set(Camera.view)
    pass.skybox.getUniform("intensity").set(sb.intensity)
    sb.cubemap.use(4)
    Screen.quad.render()
  glDepthFunc(GL_LESS)

proc renderEmission(pass: LightingPass) =
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glDepthFunc(GL_LEQUAL)
  pass.emission.use()
  pass.emission.getUniform("view").set(Camera.view)
  pass.emission.getUniform("projection").set(Camera.projection)

  for i in ModelStore().data:
    if i.emissionIntensity == 0.0: continue
    let model = i.entity.transform.matrix
    let bb = newAABB(model * i.bb.min, model * i.bb.max)
    if bb.outside(Camera.boundingBox): continue
    pass.emission.getUniform("model").set(model)
    pass.emission.getUniform("emissionIntensity").set(i.emissionIntensity)
    i.textures[0].use(0)
    i.textures[4].use(1)
    i.mesh.render()
  glDepthFunc(GL_LESS)

proc renderAmbient(pass: LightingPass) =
  pass.ambient.use()
  for i in AmbientCubeStore().data:
    pass.ambient.getUniform("eye").set(Camera.transform.position)
    pass.ambient.getUniform("colors[0]").set(i.colors[0])
    pass.ambient.getUniform("colors[1]").set(i.colors[1])
    pass.ambient.getUniform("colors[2]").set(i.colors[2])
    pass.ambient.getUniform("colors[3]").set(i.colors[3])
    pass.ambient.getUniform("colors[4]").set(i.colors[4])
    pass.ambient.getUniform("colors[5]").set(i.colors[5])
    Screen.quad.render()

proc renderIBL(pass: LightingPass) =
  pass.IBL.use()
  for i in GhettoIBLStore().data:
    pass.IBL.getUniform("eye").set(Camera.transform.position)
    pass.IBL.getUniform("lightColor").set(i.color)
    i.cubemap.use(4)
    Screen.quad.render()

proc doLighting*(pass: var LightingPass, gp: var GeometryPass, ao: var Texture, output: var Framebuffer) =
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

  gp.normal.use(0)
  gp.albedo.use(1)
  gp.depth.use(2)
  ao.use(5)

  let PV = Camera.projectionView

  for kind, shader in mpairs(pass.shaders):
    shader.use()
    shader.getUniform("eye").set(Camera.transform.position)
    shader.getUniform("invPV").set(Camera.projectionViewInverse)

    for light in LightStore().data:
      if light.kind != kind: continue
      if light.boundingBox.outside(Camera.boundingBox): continue

      if light.entity.has(CTransform):
        let t = light.entity.transform

        shader.getUniform("lightPos").set(t.position)
        shader.getUniform("lightDir").set(t.forward)
        shader.getUniform("lightSpace").set(light.getSpace())
        shader.getUniform("hasShadowmap").set(not light.shadowMap.isEmpty())

        case light.kind:
        of Point:
          shader.getUniform("lightProjection").set(perspective(90.0, 1.0, 0.1, light.radius))
          shader.getUniform("radius").set(light.radius)
        of Spot:
          shader.getUniform("cosSpotAngle").set(cos(light.spotAngle.radians))
          shader.getUniform("cosSpotFalloff").set(cos(light.spotFalloff.radians))
        else: discard

      shader.getUniform("lightColor").set(light.color)

      light.shadowMap.use(3)

      case light.kind:
      of Point:
        shader.getUniform("transform").set(PV * translate(light.entity.transform.position) * scale(light.radius))
        pass.ball.render()
      else:
        shader.getUniform("transform").set(identity())
        Screen.quad.render()

  pass.renderIBL()
  pass.renderAmbient()
  pass.renderEmission()
  pass.renderSkybox()
