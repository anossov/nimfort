import logging
import opengl

import gl/shader
import gl/texture

import engine/mesh
import engine/vector
import engine/timekeeping
import engine/resources
import engine/transform
import engine/renderer/components


type
  TextRenderer* = object
    shader: Program

proc newTextRenderer*(): TextRenderer =
  return TextRenderer(shader: getShader("text"))


proc render*(r: var TextRenderer, proj: mat4) =
  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  for i in mitems(LabelStore().data):
    if i.fade:
      i.color.w = i.color.w - (Time.delta / i.fadeTime).float32
    if i.color.w < 0.0:
      i.color.w = 0.0
      i.fade = false

  r.shader.use()
  r.shader.getUniform("projection").set(proj)
  for i in LabelStore().data:
    if i.text == "" or i.color.w == 0.0:
      continue

    i.texture.use(0)

    var shadowT = i.entity.transform.matrix
    shadowT[12] -= 2
    shadowT[13] -= 2
    r.shader.getUniform("model").set(shadowT)
    r.shader.getUniform("textColor").set(vec(0.05, 0.05, 0.05, i.color[3]))
    i.mesh.mesh.render()

    r.shader.getUniform("model").set(i.entity.transform.matrix)
    r.shader.getUniform("textColor").set(i.color)
    i.mesh.mesh.render()
