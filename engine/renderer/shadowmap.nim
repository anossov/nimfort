
import logging
import opengl

import config

import gl/shader
import gl/framebuffer
import gl/texture

import engine/vector
import engine/mesh
import engine/resources
import engine/transform
import engine/camera
import engine/renderer/components
import engine/geometry/aabb


type
  ShadowMap* = ref object
    fb: Framebuffer
    shader: Program


proc newShadowMap*(): ShadowMap =
  var
    b = newFramebuffer()
    s = getShader("shadowmap")

  glDrawBuffer(GL_NONE)
  glReadBuffer(GL_NONE)

  return ShadowMap(fb: b, shader: s)


proc createShadowMap(sm: var ShadowMap, light: var Light) =
  var t = newTexture2d(shadowMapSize, shadowMapSize, TextureFormat.Depth, PixelType.Float)
  t.clampToBorder(vec(1, 1, 1, 1))
  glTexParameteri(ord t.target, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE)

  sm.fb.attach(t, depth=true)
  light.shadowMap = t


proc render*(sm: var ShadowMap, light: var Light) =
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
  sm.shader.getUniform("lightspace").set(light.getSpace())

  let camera_bb = light.boundingBox

  for i in ModelStore().data:
    if not i.shadows:
      continue
    var model = i.entity.transform.matrix
    let bb = newAABB((model * vec(i.bb.min, 1.0)).xyz, (model * vec(i.bb.max, 1.0)).xyz)
    if bb.outside(camera_bb): continue

    sm.shader.getUniform("model").set(model)
    i.mesh.render()
