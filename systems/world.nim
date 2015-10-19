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
    handles: seq[EntityHandle]
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

  newEntity("axe").attach(newModel(
    newTransform(s=0.4),
    Resources.getMesh("axe"),
    Resources.getTexture("axe_albedo", srgb=true),
    Resources.getTexture("axe_normal"),
    Resources.getTexture("axe_roughness", srgb=true),
    Resources.getTexture("axe_metalness", srgb=true),
  ))
  
  TheWorld = World(handles: newSeq[EntityHandle]())

  TheWorld.handles.add(newEntity("sun"))
  TheWorld.handles[0].attach(newDirLight(color=vec(2, 2, 3), position=vec(1, 10, 5), shadows=false))

  newEntity("ambiance").attach(newAmbientLight(vec(0.02, 0.03, 0.04)))

  newEntity("p").attach(newPointLight(vec(3, 3, -8), vec(10, 10, 3), 8))
  
  let spot = newEntity("spot")
  spot.attach(newSpotLight(vec(3, 5, 3), target=vec(0, 0, 0), color=vec(5.3, 5.3, 5.3), angle=10, falloff=20, shadows=false))

  TheWorld.handles.add(spot)

  info("World ok")


proc updateWorld*() =
  TheWorld.handles[0].getLight().position = vec(sin(Time.totalTime * 1) * 10, cos(Time.totalTime * 1)  * 10, 4)
  TheWorld.handles[1].getLight.target = vec(0, 0, cos(Time.totalTime * 3) * 12)
  discard