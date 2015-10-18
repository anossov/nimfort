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
import renderer/rendering
import renderer/components

type
  World* = ref object
    sun: EntityHandle
    spot: EntityHandle


var TheWorld*: World


proc initWorld*() =
  var cabinM = Resources.getMesh("cabin")
  var roofM = Resources.getMesh("roof")
  var p = Resources.getMesh("quad")
  var c = Resources.getMesh("anticube")
  
  let
    w = Resources.getTexture("white")
    cd = Resources.getTexture("cabin", srgb=true)
    cs = Resources.getTexture("cabinS")
    cn = Resources.getTexture("cabinN")

    gd = Resources.getTexture("ground", srgb=true)

  newEntity("hut").attach(newModel(newTransform(s=0.1), cabinM, cd, cn, cs))
  newEntity("roof").attach(newModel(newTransform(s=0.1), roofM, cd, cn, cs))
  newEntity("ground").attach(newModel(newTransform(s=100.0), p, gd))

  newEntity("b").attach(newModel(newTransform(p=vec(3.5, 2.0, 5.5), s=1.0), Resources.getMesh("ball"), w, specular=w))
  
  TheWorld = World()

  TheWorld.sun = newEntity("sun")
  #TheWorld.sun.attach(newDirLight(color=vec(0.3, 0.3, 0.3), position=vec(20, 25, 10), shadows=true))
  newEntity("light").attach(newPointLight(color=vec(0.01, 0.01, 1), position=vec(5.5, 2.0, 5.5), radius=7.0))
  newEntity("light").attach(newPointLight(color=vec(1, 0.01, 0.01), position=vec(-5.5, 2.0, 5.5), radius=7.0))

  #newEntity("ambiance").attach(newAmbientLight(vec(0.02, 0.03, 0.04)))
  let spot = newEntity("spot")
  spot.attach(newSpotLight(vec(0, 4, 8), target=vec(2, 0, 2), color=vec(0.3, 0.3, 0.3), falloff=70, shadows=true))
  spot.attach(newModel(newTransform(p=vec(0, 2, 8), s=0.1), c, w))

  TheWorld.spot = newEntity("mini")
  TheWorld.spot.attach(newSpotLight(vec(-2.4, 12, -1), target=vec(-2.8, 0, -2), color=vec(22, 22, 22), angle=20, falloff=40, shadows=true))

  info("World ok")


proc updateWorld*() =
  TheWorld.spot.getLight.target = vec(-1 + sin(Time.totalTime * 3) * 6, 0, -1  + cos(Time.totalTime * 6))
  TheWorld.spot.getLight.position.y = 12 + sin(Time.totalTime * 2) * 3
