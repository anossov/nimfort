import opengl
import logging

import gl/buffer
import gl/shader
import gl/texture

import vector

const NO = GL_FALSE.GLboolean

type
  Vertex* = object
    position*: vec3
    uv*: vec2
    normal*: vec3
    tangent*: vec3
    bitangent*: vec3

  MeshData* = ref object
    vertices*: seq[Vertex]
    indices*: seq[uint32]

  Mesh* = object
    data*: MeshData
    texture*: Texture
    normalmap*: Texture

    vao: VAO
    vbo: Buffer
    ebo: Buffer

proc newMeshData*(): MeshData = 
  result = MeshData(
    vertices: newSeq[Vertex](),
    indices: newSeq[uint32](),
  )


proc calculateTangents*(m: var MeshData) = 
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
      f = 1.0'f32 / (duv1.x * duv2.y - duv2.x * duv1.y)
      flip = if duv2.x * duv1.y - duv2.y * duv1.x < 0: -1.0 else: 1.0

      tangent = vec(
        flip * (e2.x * duv1.y - e1.x * duv2.y),
        flip * (e2.y * duv1.y - e1.y * duv2.y),
        flip * (e2.z * duv1.y - e1.z * duv2.y),
      )
      bitangent = vec(
        flip * (e2.x * duv1.x - e1.x * duv2.x),
        flip * (e2.y * duv1.x - e1.y * duv2.x),
        flip * (e2.z * duv1.x - e1.z * duv2.x),
      )

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


proc newMesh*(data: MeshData, texture: Texture): Mesh =
  var vertices = newSeq[float32]()
  for v in data.vertices:
    vertices.add(v.position)
    vertices.add(v.uv)
    vertices.add(v.normal)
    vertices.add(v.tangent)
    vertices.add(v.bitangent)

  result = Mesh(
    data: data,
    texture: texture,
    normalmap: Texture(target: TextureTarget.t2d, id: 0),
    vao: createVAO(),
    vbo: createVBO(vertices),
    ebo: createEBO(data.indices),
  )

  let stride = GLsizei(14 * sizeof(float32))

  glVertexAttribPointer(0, 3, cGL_FLOAT, NO, stride, nil)
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(1, 2, cGL_FLOAT, NO, stride, cast[pointer](3 * sizeof(float32)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(2, 3, cGL_FLOAT, NO, stride, cast[pointer](5 * sizeof(float32)))
  glEnableVertexAttribArray(2)
  glVertexAttribPointer(3, 3, cGL_FLOAT, NO, stride, cast[pointer](8 * sizeof(float32)))
  glEnableVertexAttribArray(3)
  glVertexAttribPointer(4, 3, cGL_FLOAT, NO, stride, cast[pointer](11 * sizeof(float32)))
  glEnableVertexAttribArray(4)


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