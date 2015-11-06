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

const
  chunkSize = 32
  S = 32

type
  Block = object
    material: int
    entities: seq[EntityHandle]

  Chunk* = ref object
    x: int
    y: int
    blocks: array[chunkSize * chunkSize, Block]
    entity: EntityHandle

  World* = ref object
    chunks: Table[ivec2, Chunk]

proc terrain(): Mesh =
  result = newMesh()

  var x = 0
  for i in -S..S:
    for j in -S..S:
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

  newEntity("terrain")
    .attach(newTransform())
    .attach(newModel(
      terrain(),
      albedo=getTexture("grass"),
      roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0)),
      normal=getTexture("bevel"),
      shadows=false,
    ))

  newEntity("c")
    .attach(newTransform())
    .attach(newModel(
        getMesh("cube"),
        albedo=w,
        roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0))
    ))

  newEntity("c2")
    .attach(newTransform(s=4, p=vec(-5, 1.5, 5)))
    .attach(newModel(
        getMesh("cube"),
        albedo=w,
        roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0))
    ))

  newEntity("b")
    .attach(newTransform(p=vec(3, 0, 3), s=0.4))
    .attach(newModel(
        getMesh("ball"),
        albedo=getColorTexture(vec(1.0, 0.0, 0.0, 1.0)),
        roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0))
    ))
    .attach(Bounce(min: 0.3, max: 0.5, period: 2.0))

  info("World ok")


proc updateWorld*() =
  discard
