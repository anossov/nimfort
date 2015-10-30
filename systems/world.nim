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
import renderer/rendering
import renderer/components

type
  World* = ref object
    handles: seq[EntityHandle]

var TheWorld*: World


proc add(w: var World, name: string): EntityHandle =
  let e = newEntity(name)
  w.handles.add(e)
  return e

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
  TheWorld = World(handles: newSeq[EntityHandle]())

  for i in 0..N:
    let c = vec(random(0.4, 1.0), random(0.4, 1.0), random(0.4, 1.0), 1.0)
    TheWorld.add("point")
      .attach(newTransform(p=vec(3, 3, -8), f=vec(0, -1.0, 0.0), u=xaxis, s=0.1))
      .attach(newPointLight((c * 12).xyz, radius=5))
      .attach(newModel(getMesh("ball"), getColorTexture(c), emission=w, emissionIntensity=20))

    TheWorld.handles[i].transform.animate(p=vec(random(-20.0, 20.0), 1, random(-20.0, 20.0)), duration=6.0)

  TheWorld.add("sun")
    .attach(newTransform(f=vec(3, -8, -4.4), p=vec(-3, 5, 5), u=yaxis, s=5.0))
    .attach(newDirLight(color=vec(0.1, 0.1, 0.1), shadows=true))

  TheWorld.add("amb").attach(newAmbientCube(
    posx=vec(0.001, 0.002, 0.001),
    negx=vec(0.001, 0.002, 0.001),
    posy=vec(0.01, 0.01, 0.03),
    negy=vec(0.01, 0.0, 0.0),
    posz=vec(0.001, 0.002, 0.001),
    negz=vec(0.001, 0.002, 0.001),
  ))

  TheWorld.add("terrain")
    .attach(newTransform())
    .attach(newModel(
      terrain(),
      albedo=getColorTexture(vec(0.5, 0.5, 0.5, 1.0)),
      roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0)),
      normal=getTexture("bevel"),
    ))

  TheWorld.add("c")
    .attach(newTransform())
    .attach(newModel(
        getMesh("cube"),
        albedo=w,
        roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0))
    ))

  info("World ok")



proc updateWorld*() =
  for i in 0..N:
    if TheWorld.handles[i].animation.done:
      TheWorld.handles[i].transform.animate(p=vec(random(-20.0, 20.0), 1, random(-20.0, 20.0)), duration=random(0.5, 10.0))
