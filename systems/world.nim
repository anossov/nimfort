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
  var p = Resources.getMesh("cube")
  var ball = Resources.getMesh("ball")
  var c = Resources.getMesh("lightcone")

  let
    w = Resources.getTexture("white")
    cone = Resources.getTexture("lightcone", srgb=true)
    coneE = Resources.getTexture("lightconeE", srgb=true)
    coneR = Resources.getTexture("lightconeR", srgb=true)

  TheWorld = World(handles: newSeq[EntityHandle]())

  TheWorld.add("axe")
    .attach(newTransform(s=0.4))
    .attach(newModel(
      Resources.getMesh("axe"),
      Resources.getTexture("axe_albedo", srgb=true),
      Resources.getTexture("axe_normal"),
      Resources.getTexture("axe_roughness", srgb=true),
      Resources.getTexture("axe_metalness", srgb=true),
    ))

  #newEntity("ambiance").attach(newAmbientLight(vec(0.02, 0.03, 0.04)))

  TheWorld.add("point")
    .attach(newTransform(p=vec(3, 3, -8), f=vec(0, -1.0, 0.0), u=xaxis, s=0.1))
    .attach(newPointLight(vec(2, 2, 5), radius=7))
    .attach(newModel(ball, w, emission=w, emissionIntensity=20))
    .attach(CircleMovement(rvector: vec(0, 5, 0), period: 1, axis: zaxis, center: vec(0, 0, -8)))

  TheWorld.add("spot")
    .attach(newSpotLight(color=vec(2, 2, 1), angle=30, falloff=50, shadows=true))
    .attach(newTransform(p=vec(7, 7, 10), f=vec(-7, -7, -5), s=0.5))
    .attach(newModel(c, cone, roughness=coneR, emission=coneE, emissionIntensity=16, shadows=false))

  TheWorld.add("g")
    .attach(newTransform(p=vec(-8, 0, 0), f=vec(0, 1, 0), u=xaxis, s=20))
    .attach(newModel(
      Resources.getMesh("quad"),
      Resources.getTexture("axe_albedo", srgb=true),
      Resources.getTexture("axe_normal"),
      Resources.getTexture("axe_roughness", srgb=true),
      Resources.getTexture("axe_metalness", srgb=true),
    ))

  TheWorld.add("sun2")
    .attach(newTransform(f=vec(-1, 0.5, 0.5), p=vec(20, 0, 0), u=yaxis, s=0.3))
    .attach(newDirLight(color=vec(0.5, 0.5, 0.5), shadows=true))
    .attach(newModel(c, cone, roughness=coneR, emission=coneE, emissionIntensity=16))

  info("World ok")

proc updateWorld*() =
  TheWorld.handles[0].transform.setUp(vec(cos(Time.totalTime / 1), sin(Time.totalTime / 1), 0))
  TheWorld.handles[0].transform.updateMatrix()
  TheWorld.handles[1].circleMovement.center.z = sin(Time.totalTime * 1) * 10
  discard
