import logging
import mesh
import math
import gl/texture
import objfile
import vector
import strutils
import random

import systems/ecs
import systems/resources
import systems/timekeeping
import systems/transform
import systems/messaging
import systems/camera
import renderer/rendering
import renderer/components

type
  World* = ref object
    listener: Listener
    cursor*: ivec3
    selection*: array[2, ivec3]
    selecting*: bool

var TheWorld*: World


const
  N = 12
  S = 100


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


proc initWorld*() =
  let w = getColorTexture(vec(1.0, 1.0, 1.0, 1.0))
  TheWorld = World(
    listener: newListener(),
  )
  TheWorld.listener.listen("world")

  for i in 0..N:
    let c = vec(random(0.4, 1.0), random(0.4, 1.0), random(0.4, 1.0), 1.0)
    newEntity("point-" & $i)
      .attach(newTransform(p=vec(0, 3, 0), f=vec(0, -1.0, 0.0), u=xaxis, s=0.1))
      .attach(newPointLight((c * 12).xyz, radius=5))
      .attach(newModel(getMesh("ball"), getColorTexture(c), emission=w, emissionIntensity=20))
      .attach(RandomMovement(min: vec(-100, 0.0, -100), max: vec(100, 0.0, 100), smin: 20, smax: 20))
      .attach(Animation(done: true))
      .attach(Bounce(min: 2.0, max: 4.0, period: 1.0))

  newEntity("sun")
    .attach(newTransform(f=vec(3, -11, -4.4), p=vec(-3, 5, 5), u=yaxis, s=5.0))
    .attach(newDirLight(color=vec(0.2, 0.2, 0.2), shadows=true))

  newEntity("amb").attach(newAmbientCube(
    posx=vec(0.001, 0.002, 0.001),
    negx=vec(0.001, 0.002, 0.001),
    posy=vec(0.01, 0.01, 0.03),
    negy=vec(0.01, 0.0, 0.0),
    posz=vec(0.001, 0.002, 0.001),
    negz=vec(0.001, 0.002, 0.001),
  ))

  newEntity("terrain")
    .attach(newTransform())
    .attach(newModel(
      terrain(),
      albedo=getColorTexture(vec(0.5, 0.5, 0.5, 1.0)),
      roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0)),
      normal=getTexture("bevel"),
    ))

  newEntity("c")
    .attach(newTransform())
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
  let p = Camera.pickGround(-0.5) + vec(0, 0.5, 0)
  TheWorld.cursor = ivec(p.x.round, p.y.round, p.z.round)

  for m in TheWorld.listener.getMessages():
    var p = m.parser()
    try:
      case m.name:

      of "move":
        let e = p.parseEntity()
        if e.has("Transform"):
          e.transform.position = TheWorld.cursor.toFloat()
          e.transform.updateMatrix()

      of "selection-start":
        TheWorld.selection[0] = TheWorld.cursor
        TheWorld.selecting = true

      of "selection-end":
        TheWorld.selecting = false

      else: discard

    except ValueError:
      Messages.emit("error", getCurrentExceptionMsg())

  if TheWorld.selecting:
    TheWorld.selection[1] = TheWorld.cursor
