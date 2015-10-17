import logging
import opengl
import gl/shader
import gl/framebuffer
import gl/texture
import vector
import mesh
import systems/resources
import renderer/components
import config

type
  ShadowMap* = ref object
    fb: Framebuffer
    shader: Program


proc newShadowMap*(): ShadowMap =
  var
    b = newFramebuffer()
    s = Resources.getShader("shadowmap")

  glDrawBuffer(GL_NONE)
  glReadBuffer(GL_NONE)

  return ShadowMap(fb: b, shader: s)


proc createShadowMap(sm: var ShadowMap, light: var Light) =
  var t = newTexture()
  t.image2d(nil, shadowMapSize, shadowMapSize, false, TextureFormat.Depth, PixelType.Float, GL_DEPTH_COMPONENT)
  t.filter(true)

  glTexParameteri(ord t.target, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE)
  glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)

  var border = [1'f32, 1, 1, 1]
  glTexParameterfv(ord t.target, GL_TEXTURE_BORDER_COLOR, addr border[0])

  sm.fb.attach(t, depth=true)
  light.shadowMap = t


proc render*(sm: var ShadowMap, light: var Light, geometry: seq[Model]) =
  if not light.shadows:
    return

  sm.fb.use()

  if light.shadowMap.isEmpty():
    sm.createShadowMap(light)

  sm.fb.attach(light.shadowMap, depth=true)
  
  glEnable(GL_DEPTH_TEST)
  glDepthMask(true)
  glClear(GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, shadowMapSize, shadowMapSize)
  
  sm.shader.use()
  sm.shader.getUniform("lightspace").set(light.getProjection() * light.getView())

  for i in geometry:
    if not i.shadows:
      continue
    var model = i.transform.matrix
    sm.shader.getUniform("model").set(model)
    i.mesh.render()