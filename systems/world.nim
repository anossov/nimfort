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


var TheWorld*: World


proc initWorld*() =
  var cabinM = Resources.getMesh("cabin")
  var roofM = Resources.getMesh("roof")
  var p = Resources.getMesh("quad")
  
  let
    cd = Resources.getTexture("cabin", srgb=true)
    cs = Resources.getTexture("cabinS")
    cn = Resources.getTexture("cabinN")

    gd = Resources.getTexture("ground", srgb=true)

  newEntity("hut").attach(newModel(newTransform(s=0.02), cabinM, cd, cn, cs))
  newEntity("roof").attach(newModel(newTransform(s=0.02), roofM, cd, cn, cs))
  newEntity("ground").attach(newModel(newTransform(s=100.0), p, gd))
  
  TheWorld = World()

  TheWorld.sun = newEntity("sun")
  TheWorld.sun.attach(newLight(Directional, shadows=true))
  
  newEntity("p").attach(newLight(Point, vec(0.0, 0.2, 0.1), attenuation=vec(1.0, 0.0, 150.0)))

  newEntity("p").attach(newLight(Point, vec(1.0, 0.2, 0.0), attenuation=vec(1.0, 5.0, 150.0)))
  newEntity("p").attach(newLight(Point, vec(0.0, 0.2, 1.0), attenuation=vec(1.0, 5.0, 150.0)))
  newEntity("p").attach(newLight(Point, vec(0.0, 0.2, -1.0), attenuation=vec(1.0, 5.0, 150.0)))
  newEntity("p").attach(newLight(Point, vec(-1.0, 0.2, 0.0), attenuation=vec(1.0, 5.0, 150.0)))

  info("World ok")


proc updateWorld*() =
  TheWorld.sun.getLight.position = vec(sin(Time.totalTime / 4.0)*5, cos(Time.totalTime / 4.0)*5, 5)