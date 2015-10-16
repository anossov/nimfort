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
  ShadowMap* = object
    fb: Framebuffer
    texture*: Texture
    shader: Program


proc newShadowMap*(): ShadowMap =
  var
    b = newFramebuffer()
    t = newTexture()
    s = Resources.getShader("shadowmap")

  t.image2d(nil, shadowMapSize, shadowMapSize, false, TextureFormat.Depth, PixelType.Float, GL_DEPTH_COMPONENT)
  t.filter(true)

  glTexParameteri(ord t.target, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE)
  glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)

  var border = [1'f32, 1, 1, 1]
  glTexParameterfv(ord t.target, GL_TEXTURE_BORDER_COLOR, addr border[0])

  b.attach(t, depth=true)

  glDrawBuffer(GL_NONE)
  glReadBuffer(GL_NONE)

  debug("Shadow map: $1", b.check())

  return ShadowMap(fb: b, texture: t, shader: s)


proc render*(sm: var ShadowMap, lightspace: var mat4, geometry: seq[Renderable3d]) =
  sm.fb.use()
  glEnable(GL_DEPTH_TEST)
  glClear(GL_DEPTH_BUFFER_BIT)
  glViewport(0, 0, shadowMapSize, shadowMapSize)
  
  sm.shader.use()
  sm.shader.getUniform("lightspace").set(lightspace)

  for i in geometry:
    var model = i.transform.matrix
    sm.shader.getUniform("model").set(model)
    i.mesh.render()