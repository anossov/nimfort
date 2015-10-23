import logging
import mesh
import math
import gl/texture
import objfile
import vector
import strutils

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


proc initWorld*() =
  var p = getMesh("cube")
  var ball = getMesh("ball")
  var c = getMesh("lightcone")

  let
    w = getColorTexture(vec(1.0, 1.0, 1.0, 1.0))
    cone = getTexture("lightcone", srgb=true)
    coneE = getTexture("lightconeE", srgb=true)
    coneR = getTexture("lightconeR", srgb=true)

  TheWorld = World(handles: newSeq[EntityHandle]())

  TheWorld.add("axe")
    .attach(newTransform(s=0.4))
    .attach(newModel(
      getMesh("axe"),
      getTexture("axe_albedo", srgb=true),
      getTexture("axe_normal"),
      getTexture("axe_roughness", srgb=true),
      getTexture("axe_metalness", srgb=true),
    ))

  TheWorld.add("point")
    .attach(newTransform(p=vec(3, 3, -8), f=vec(0, -1.0, 0.0), u=xaxis, s=0.1))
    .attach(newPointLight(vec(3, 3, 3), radius=7))
    .attach(newModel(ball, w, emission=w, emissionIntensity=20))
    .attach(CircleMovement(rvector: vec(0, 5, 0), period: 1, axis: zaxis, center: vec(0, 0, -8)))

  TheWorld.add("spot")
    .attach(newSpotLight(color=vec(2, 2, 2), angle=30, falloff=50, shadows=true))
    .attach(newTransform(p=vec(7, 7, 10), f=vec(-7, -7, -5), s=0.5))
    .attach(newModel(c, cone, roughness=coneR, emission=coneE, emissionIntensity=16, shadows=false))

  TheWorld.add("g")
    .attach(newTransform(p=vec(-8, 0, 0), f=vec(0, 1, 0), u=xaxis, s=20))
    .attach(newModel(
      getMesh("quad"),
      getTexture("axe_albedo", srgb=true),
      getTexture("axe_normal"),
      getTexture("axe_roughness", srgb=true),
      getTexture("axe_metalness", srgb=true),
    ))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(1.00, 0.71, 0.29, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.1, 0.1, 0.1, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, 0)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.95, 0.64, 0.54, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.1, 0.1, 0.1, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, 3)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.95, 0.93, 0.88, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.1, 0.1, 0.1, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, -3)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.91, 0.92, 0.92, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.1, 0.1, 0.1, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, 6)))


  TheWorld.add("sun")
    .attach(newTransform(f=vec(-15, 0.5, 0.5), p=vec(20, 0, 0), u=yaxis, s=2.0))
    .attach(newDirLight(color=vec(0.5, 0.5, 0.5), shadows=true))
    .attach(newModel(getMesh("quadZ"), w, emission=w, emissionIntensity=16))

  info("World ok")

proc updateWorld*() =
  TheWorld.handles[0].transform.setUp(vec(cos(Time.totalTime / 1), sin(Time.totalTime / 1), 0))
  TheWorld.handles[0].transform.updateMatrix()
  TheWorld.handles[1].circleMovement.center.z = sin(Time.totalTime * 1) * 10

  TheWorld.handles[2].model.emissionIntensity = sin(Time.totalTime) * 16 + 17
  TheWorld.handles[2].light.color = vec(2, 2, 2) * (sin(Time.totalTime) + 1)
