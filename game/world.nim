import logging
import math
import strutils
import random

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


type
  World* = ref object
    listener: Listener


var TheWorld*: World


const
  N = 20
  S = 50
  NT = 500


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
      .attach(newPointLight((c * 24).xyz, radius=8, shadows=true))
      .attach(newModel(getMesh("ball"), getColorTexture(c), emission=w, emissionIntensity=5, emissionOnly=true))
      .attach(RandomMovement(min: vec(-S, 0.0, -S), max: vec(S, 0.0, S), smin: 1, smax: 3))
      .attach(Animation(done: true))
      .attach(Bounce(min: 2.5, max: 3.0, period: 1.0))

  for i in 0..NT:
    let
      p = vec(random(-S, S).floor, 0, random(-S, S).floor)
      f = vec(random(-1, 1), 0, random(-1, 1))
      s = random(1.0, 1.5)
    newEntity("tree")
    .attach(newTransform(p=p, f=f, s=s))
    .attach(newModel(
      getMesh("tree"),
      albedo=getColorTexture(vec(0.5, 0.25, 0.15, 1.0)),
      roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0)),
    ))

  newEntity("sun")
    .attach(newTransform(f=vec(3, -11, -4.4), p=vec(-3, 5, 5), u=yaxis))
  #  .attach(newDirLight(color=vec(1, 1, 1), shadows=true))


  newEntity("amb").attach(newAmbientCube(
    posx=vec(0.01, 0.02, 0.01),
    negx=vec(0.01, 0.02, 0.01),
    posy=vec(0.03, 0.04, 0.05),
    negy=vec(0.01, 0.0, 0.0),
    posz=vec(0.01, 0.02, 0.1),
    negz=vec(0.01, 0.02, 0.01),
  ))

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
