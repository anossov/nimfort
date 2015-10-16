import opengl
import gl/shader
import gl/texture
import mesh
import vector
import systems/resources
import renderer/components

type
  TextRenderer* = object
    shader: Program

proc newTextRenderer*(): TextRenderer = 
  return TextRenderer(shader: Resources.getShader("text"))


proc render*(r: var TextRenderer, proj: var mat4, labels: seq[Label]) = 
  glDisable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 

  r.shader.use()
  r.shader.getUniform("projection").set(proj)
  for i in labels:
    var model = i.transform.matrix
    r.shader.getUniform("model").set(model)
    i.mesh.texture.use(0)
    i.mesh.render()