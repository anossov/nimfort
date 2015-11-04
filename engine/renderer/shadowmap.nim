import logging
import opengl
import strutils

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
    shaderCube: Program


proc newShadowMap*(): ShadowMap =
  var
    b = newFramebuffer()

  glDrawBuffer(GL_NONE)
  glReadBuffer(GL_NONE)

  return ShadowMap(fb: b, shader: getShader("shadowmap"), shaderCube: getShader("shadowcubemap"))


proc createShadowMap(sm: var ShadowMap, light: var Light) =
  var t: Texture

  if light.kind == Point:
    t = newTexture(TextureTarget.CubeMap)
    let
      size = cubeShadowMapSize.int32
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


proc render*(sm: var ShadowMap, light: var Light) =
  if not light.shadows:
    return

  sm.fb.use()

  if light.shadowMap.isEmpty():
    sm.createShadowMap(light)

  glEnable(GL_DEPTH_TEST)
  glDepthMask(true)

  sm.fb.attach(light.shadowMap, depth=true)
  glClear(GL_DEPTH_BUFFER_BIT)

  var s: Program

  if light.kind == Point:
    s = sm.shadercube
    glViewport(0, 0, cubeShadowMapSize, cubeShadowMapSize)
    s.use()
    for i, f in cubeMapFaces:
      s.getUniform("shadowMatrices[$1]".format(i)).set(light.getFaceSpace(f))
  else:
    s = sm.shader
    glViewport(0, 0, shadowMapSize, shadowMapSize)
    s.use()
    s.getUniform("lightspace").set(light.getSpace())

  let camera_bb = light.boundingBox

  for i in ModelStore().data:
    if not i.shadows:
      continue
    var model = i.entity.transform.matrix
    let bb = newAABB(model * i.bb.min, model * i.bb.max)
    if bb.outside(camera_bb): continue

    s.getUniform("model").set(model)
    i.mesh.render()
