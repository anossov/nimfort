
import logging
import opengl

import config

import gl/shader
import gl/framebuffer
import gl/texture

import engine/ecs
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
  var t: Texture

  if light.kind == Point:
    t = newTexture(TextureTarget.CubeMap)
    let
      size = (shadowMapSize shr 2).int32
      f = ord TextureFormat.Depth
      pt = ord PixelType.Float
    for face in cubeMapFaces:
      glTexImage2D(face.GLenum, 0, GL_DEPTH_COMPONENT.GLint, size, size, 0, f.GLenum, pt.GLenum, nil)
    t.filter(true)
  else:
    t = newTexture2d(shadowMapSize, shadowMapSize, TextureFormat.Depth, PixelType.Float)

  t.clampToBorder(vec(1, 1, 1, 1))
  glTexParameteri(ord t.target, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_R_TO_TEXTURE)

  light.shadowMap = t

const
  targetscube = @cubeMapFaces
  targets2d = @[ord TextureTarget.Texture2d]

proc render*(sm: var ShadowMap, light: var Light) =
  if not light.shadows:
    return

  sm.fb.use()

  if light.shadowMap.isEmpty():
    sm.createShadowMap(light)

  glEnable(GL_DEPTH_TEST)
  glDepthMask(true)

  if light.kind == Point:
    glViewport(0, 0, shadowMapSize shr 2, shadowMapSize shr 2)
  else:
    glViewport(0, 0, shadowMapSize, shadowMapSize)

  sm.shader.use()

  var targets = if light.kind == Point: targetscube else: targets2d

  let camera_bb = light.boundingBox

  for t in targets:
    sm.fb.attach(light.shadowMap, depth=true, tt=t)
    glClear(GL_DEPTH_BUFFER_BIT)

    if light.kind == Point:
      sm.shader.getUniform("lightspace").set(light.getFaceSpace(t))
    else:
      sm.shader.getUniform("lightspace").set(light.getSpace())

    for i in ModelStore().data:
      if not i.shadows:
        continue
      var model = i.entity.transform.matrix
      let bb = newAABB((model * vec(i.bb.min, 1.0)).xyz, (model * vec(i.bb.max, 1.0)).xyz)
      if bb.outside(camera_bb): continue

      sm.shader.getUniform("model").set(model)
      i.mesh.render()
