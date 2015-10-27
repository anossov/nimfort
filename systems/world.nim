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
    .attach(newPointLight(vec(12, 12, 12), radius=5))
    .attach(newModel(ball, w, emission=w, emissionIntensity=20))
    .attach(CircleMovement(rvector: vec(0, 3, 0), period: 1, axis: zaxis, center: vec(0, 0, -8)))

  TheWorld.add("spot")
    .attach(newSpotLight(color=vec(2, 2, 2), angle=30, falloff=50, shadows=true))
    .attach(newTransform(p=vec(7, 7, 10), f=vec(-7, -7, -5), s=0.5))
    .attach(newModel(c, cone, roughness=coneR, emission=coneE, emissionIntensity=16, shadows=false))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.56, 0.57, 0.58 , 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.05, 0.05, 0.05, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, -4)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.95, 0.93, 0.88, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.25, 0.25, 0.25, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, -1)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(1.00, 0.71, 0.29, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.50, 0.50, 0.50, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, 2)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(1.00, 0.71, 0.29, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.05, 0.05, 0.05, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, -3, 2)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.95, 0.64, 0.54, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.75, 0.75, 0.75, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, 5)))

  TheWorld.add("b")
    .attach(newModel(
      ball,
      getColorTexture(vec(0.91, 0.92, 0.92, 1.0)),
      emptyTexture(),
      getColorTexture(vec(0.98, 0.98, 0.98, 1.0)),
      getColorTexture(vec(1.0, 1.0, 1.0, 1.0)),
    ))
    .attach(newTransform(p=vec(0, 3, 8)))

  TheWorld.add("sky").attach(newSkyBox(getCubeMap("lake"), vec(2.0, 2.0, 2.0)))

  TheWorld.add("sun")
    .attach(newTransform(f=vec(3, -3, -5), p=vec(-3, 3, 5)*20, u=yaxis, s=5.0))
    .attach(newDirLight(color=vec(3, 3, 3), shadows=true))
    .attach(newModel(getMesh("ball"), w, emission=w, emissionIntensity=16))

  TheWorld.add("ibl").attach(newGhettoIBL(getCubeMap("lake"), vec(0.8, 0.8, 0.8)))

  TheWorld.add("amb").attach(newAmbientCube(
    posx=vec(0.001, 0.002, 0.001),
    negx=vec(0.001, 0.002, 0.001),
    posy=vec(0.001, 0.001, 0.003),
    negy=vec(0.01, 0.0, 0.0),
    posz=vec(0.001, 0.002, 0.001),
    negz=vec(0.001, 0.002, 0.001),
  ))

  info("World ok")

proc updateWorld*() =
  TheWorld.handles[0].transform.setUp(vec(cos(Time.totalTime / 1), sin(Time.totalTime / 1), 0))
  TheWorld.handles[0].transform.updateMatrix()
  TheWorld.handles[1].circleMovement.center.z = sin(Time.totalTime * 1) * 10

  TheWorld.handles[2].model.emissionIntensity = sin(Time.totalTime) * 16 + 17
 #TheWorld.handles[2].light.color = vec(2, 2, 2) * (sin(Time.totalTime) + 1)
