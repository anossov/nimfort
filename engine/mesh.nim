import opengl
import logging

import gl/buffer
import gl/shader
import gl/texture

import engine/vector


const NO = GL_FALSE.GLboolean

type
  Vertex* = object
    position*: vec3
    uv*: vec2
    normal*: vec3
    tangent*: vec3
    bitangent*: vec3

  Mesh* = object
    vertices*: seq[Vertex]
    indices*: seq[uint32]

    vbo: Buffer
    ebo: Buffer


var meshesRendered*: int

var vao: VAO

proc newMesh*(): Mesh =
  result = Mesh(
    vertices: newSeq[Vertex](),
    indices: newSeq[uint32](),
    vbo: emptyBuffer(BufferTarget.Array),
    ebo: emptyBuffer(BufferTarget.ElementArray),
  )


proc calculateTangents*(m: var Mesh) =
  let numFaces = m.indices.len div 3

  var
    adjacentFaces = newSeq[seq[int]](m.vertices.len)
    tangents = newSeq[vec3](numFaces)
    bitangents = newSeq[vec3](numFaces)

  for i, v in m.vertices:
    adjacentFaces[i] = newSeq[int]()

  for face in 0..numFaces-1:
    let
      i1 = m.indices[face * 3].int
      i2 = m.indices[face * 3 + 1].int
      i3 = m.indices[face * 3 + 2].int
      v1 = m.vertices[i1]
      v2 = m.vertices[i2]
      v3 = m.vertices[i3]
      e1 = v2.position - v1.position
      e2 = v3.position - v1.position
      duv1 = v2.uv - v1.uv
      duv2 = v3.uv - v1.uv
      f = 1.0'f32 / (duv1.y * duv2.x - duv2.y * duv1.x)
      tangent = (e1 * -duv2.y + e2 * duv1.y) * f
      bitangent = (e1 * -duv2.x + e2 * duv1.x) * f

    tangents[face] = tangent
    bitangents[face] = bitangent
    adjacentFaces[i1].add(face)
    adjacentFaces[i2].add(face)
    adjacentFaces[i3].add(face)

  for i, v in mpairs(m.vertices):
    for face in adjacentFaces[i]:
      v.tangent = v.tangent + tangents[face] - v.normal * (tangents[face].dot(v.normal))
      v.bitangent = v.bitangent + bitangents[face] - v.normal * (bitangents[face].dot(v.normal))
    v.tangent = v.tangent.normalize()
    v.bitangent = v.bitangent.normalize()


proc buildBuffers*(m: var Mesh) =
  var vertices = newSeq[float32]()
  for v in m.vertices:
    vertices.add(v.position)
    vertices.add(v.uv)
    vertices.add(v.normal)
    vertices.add(v.tangent)
    vertices.add(v.bitangent)

  if not vao.initialized:
    vao = createVAO()
    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)
    glEnableVertexAttribArray(2)
    glEnableVertexAttribArray(3)
    glEnableVertexAttribArray(4)

  m.vbo = createVBO(vertices)
  m.ebo = createEBO(m.indices)


proc render*(m: Mesh) =
  m.vbo.use()
  let stride = GLsizei(14 * sizeof(float32))
  glVertexAttribPointer(0, 3, cGL_FLOAT, NO, stride, nil)
  glVertexAttribPointer(1, 2, cGL_FLOAT, NO, stride, cast[pointer](3 * sizeof(float32)))
  glVertexAttribPointer(2, 3, cGL_FLOAT, NO, stride, cast[pointer](5 * sizeof(float32)))
  glVertexAttribPointer(3, 3, cGL_FLOAT, NO, stride, cast[pointer](8 * sizeof(float32)))
  glVertexAttribPointer(4, 3, cGL_FLOAT, NO, stride, cast[pointer](11 * sizeof(float32)))
  m.ebo.use()
  glDrawElements(GL_TRIANGLES, len(m.indices).GLsizei, GL_UNSIGNED_INT, nil)
  meshesRendered.inc


proc deleteBuffers*(m: var Mesh) =
  m.vbo.use()
  m.vbo.delete()
  m.ebo.use()
  m.ebo.delete()
