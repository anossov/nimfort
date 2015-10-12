import opengl

import gl/buffer
import gl/shader
import gl/texture

const NO = GL_FALSE.GLboolean

type
  Mesh* = object
    vertices*: seq[GLfloat]
    ntriangles*: int
    texture*: Texture

    vao: VAO
    vbo: Buffer

proc newMesh*(vertices: var seq[GLfloat], texture: Texture, position=3, uv=2, normals=3): Mesh =
  result = Mesh(
    vertices: vertices,
    ntriangles: len(vertices) div (position + uv + normals),
    texture: texture,
    vao: createVAO(),
    vbo: createVBO(vertices),
  )

  let stride = GLsizei((position + uv + normals) * sizeof(GLfloat))
  var offset = position

  glVertexAttribPointer(0, position.GLint, cGL_FLOAT, NO, stride, nil)
  glEnableVertexAttribArray(0)

  if uv > 0:
    glVertexAttribPointer(1, uv.GLint, cGL_FLOAT, NO, stride, cast[pointer](offset * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)
    offset += uv

  if normals > 0:
    glVertexAttribPointer(2, normals.GLint, cGL_FLOAT, NO, stride, cast[pointer](offset * sizeof(GLfloat)))
    glEnableVertexAttribArray(2)


proc render*(m: Mesh) =
  m.vao.use()
  m.texture.use()
  glDrawArrays(GL_TRIANGLES, 0, m.ntriangles.GLsizei)


proc deleteBuffers*(m: var Mesh) =
  m.vao.use()
  glDisableVertexAttribArray(0)
  glDisableVertexAttribArray(1)
  glDisableVertexAttribArray(2)
  m.vbo.use()
  m.vbo.delete()
  m.vao.delete()