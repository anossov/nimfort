import logging
import math
import strutils
import random
import tables

import engine/vector
import engine/mesh
import engine/ecs
import engine/resources
import engine/timekeeping
import engine/transform
import engine/messaging
import engine/camera
import engine/renderer/rendering
import engine/renderer/components
import engine/geometry/aabb

const
  chunkSize = 32

type
  Block = object
    material: int

  Object = object
    pos*: ivec3
    entity*: EntityHandle

  Chunk* = ref object
    pos*: ivec2
    blocks: array[chunkSize * chunkSize, Block]
    objects*: seq[Object]
    entity: EntityHandle

  World* = ref object
    chunks*: Table[ivec2, Chunk]

var emptyChunk = Chunk(objects: newSeq[Object]())

proc terrain(): Mesh =
  result = newMesh()

  var x = 0
  for i in 0..chunkSize - 1:
    for j in 0..chunkSize - 1:
      let
        fi = i.float() - 0.5
        fj = j.float() - 0.5
      result.vertices.add([
        Vertex(position: vec(fi,       -0.5, fj + 1.0), uv: vec(0, 1), normal: yaxis, tangent: xaxis, bitangent: zaxis),
        Vertex(position: vec(fi,       -0.5, fj      ), uv: vec(0, 0), normal: yaxis, tangent: xaxis, bitangent: zaxis),
        Vertex(position: vec(fi + 1.0, -0.5, fj      ), uv: vec(1, 0), normal: yaxis, tangent: xaxis, bitangent: zaxis),
        Vertex(position: vec(fi + 1.0, -0.5, fj + 1.0), uv: vec(1, 1), normal: yaxis, tangent: xaxis, bitangent: zaxis),
      ])

      result.indices.add([
        uint32(x * 4 + 0),
        uint32(x * 4 + 2),
        uint32(x * 4 + 1),
        uint32(x * 4 + 0),
        uint32(x * 4 + 3),
        uint32(x * 4 + 2),
      ])
      x += 1

  result.buildBuffers()


proc newWorld*(): World =
  let w = getColorTexture(vec(1.0, 1.0, 1.0, 1.0))
  result = World(
    chunks: initTable[ivec2, Chunk]()
  )

  info("World ok")


proc newChunk(p: ivec2): Chunk =
  var wp = ivec(p.x * chunkSize, 0, p.y * chunkSize)
  result = Chunk(
    objects: newSeq[Object](),
  )
  result.pos = p
  result.entity = newEntity("chunk-($1 $2)".format(p.x, p.y))
  result.entity
    .attach(newTransform(p=wp.toFloat))
    .attach(newModel(
      terrain(),
      albedo=getTexture("grass"),
      roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0)),
      normal=getTexture("bevel"),
      shadows=false,
    ))

  for i in randomSample(0..chunkSize*chunkSize-1, randomInt(0, chunkSize)):
    let x = (i mod chunkSize).int32
    let y = (i div chunkSize).int32
    let e = newEntity("tree")
      .attach(newTransform(p=wp.toFloat + vec(x.float, 0.0, y.float)))
      .attach(newModel(
        getMesh("tree"),
        albedo=getColorTexture(vec(0.5, 0.4, 0.1, 1.0)),
        roughness=getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
        shadows=true,
      ))

    result.objects.add(Object(entity: e, pos: wp + ivec(x, 0, y)))

  return result


proc chunkCoord*(p: ivec3): ivec2 = (p.toFloat / chunkSize).floor.toInt.xz

iterator grid2d(a, b: ivec2): ivec2 =
  for x in a.x .. b.x:
    for y in a.y .. b.y:
      yield ivec(x, y)


iterator objectsAt*(w: World, p: ivec3): Object =
  for o in w.chunks[p.chunkCoord].objects:
    if o.pos == p:
      yield o

iterator objectsIn*(w: World; bb: AABB): Object =
  let
    a = bb.min.xyz.toInt.chunkCoord
    b = bb.max.xyz.toInt.chunkCoord
  for p in grid2d(a, b):
    if w.chunks.hasKey(p):
      for o in w.chunks[p].objects:
        if o.pos.toFloat in bb:
          yield o

proc updateWorld*(w: World) =
  let bb = Camera.boundingBox

  for p in grid2d(bb.min.xyz.toInt.chunkCoord, bb.max.xyz.toInt.chunkCoord):
    if not w.chunks.hasKey(p):
      w.chunks[p] = newChunk(p)
