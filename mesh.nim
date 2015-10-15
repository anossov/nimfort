import opengl
import logging

import gl/buffer
import gl/shader
import gl/texture

const NO = GL_FALSE.GLboolean

type
  Vertex* = object
    position*: array[3, float32]
    normal*: array[3, float32]
    uv*: array[2, float32]

  MeshData* = ref object
    vertices*: seq[Vertex]
    indices*: seq[uint32]

  Mesh* = object
    data*: MeshData
    texture*: Texture

    vao: VAO
    vbo: Buffer
    ebo: Buffer

proc newMeshData*(): MeshData = 
  result = MeshData(
    vertices: newSeq[Vertex](),
    indices: newSeq[uint32](),
  )

proc newMesh*(data: MeshData, texture: Texture): Mesh =
  var vertices = newSeq[float32]()
  for v in data.vertices:
    vertices.add(v.position)
    vertices.add(v.uv)
    vertices.add(v.normal)

  result = Mesh(
    data: data,
    texture: texture,
    vao: createVAO(),
    vbo: createVBO(vertices),
    ebo: createEBO(data.indices),
  )

  let stride = GLsizei(8 * sizeof(float32))

  glVertexAttribPointer(0, 3, cGL_FLOAT, NO, stride, nil)
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 2, cGL_FLOAT, NO, stride, cast[pointer](3 * sizeof(float32)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(2, 3, cGL_FLOAT, NO, stride, cast[pointer](5 * sizeof(float32)))
  glEnableVertexAttribArray(2)


proc render*(m: Mesh) =
  m.vao.use()
  glDrawElements(GL_TRIANGLES, len(m.data.indices).GLsizei, GL_UNSIGNED_INT, nil)


proc deleteBuffers*(m: var Mesh) =
  m.vao.use()
  glDisableVertexAttribArray(0)
  glDisableVertexAttribArray(1)
  glDisableVertexAttribArray(2)
  m.vbo.use()
  m.vbo.delete()
  m.ebo.use()
  m.ebo.delete()
  m.vao.delete()