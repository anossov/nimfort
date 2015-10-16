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
  var cabinM = Resources.getModel("cabin")
  var roofM = Resources.getModel("roof", false)
  var p = Resources.getModel("quad", false)
  
  let
    cs = Resources.getTexture("cabinS", false)
    cn = Resources.getTexture("cabinN", false)

  p.texture = Resources.getTexture("ground")
  #p.normalmap = Resources.getTexture("groundN")
  #p.specularmap = Resources.getTexture("white")
  cabinM.normalmap = cn
  cabinM.specularmap = cs
  roofM.texture = cabinM.texture
  roofM.normalmap = cn
  roofM.specularmap = cs
  
  newEntity("hut").attach(Renderable3d(transform: newTransform(zeroes3, zeroes3, ones3 * 0.02), mesh: cabinM))
  newEntity("roof").attach(Renderable3d(transform: newTransform(zeroes3, zeroes3, ones3 * 0.02), mesh: roofM))
  newEntity("ground").attach(Renderable3d(transform: newTransform(vec(0.0, 0.0, 0.0), zeroes3, ones3 * 10.0), mesh: p))
  
  TheWorld = World()

  TheWorld.sun = newEntity("sun")
  TheWorld.sun.attach(newLight(Directional, shadows=true))
  
  newEntity("p").attach(newLight(Point, position=vec(0.0, 0.2, 0.8), attenuation=vec(1.0, 0.0, 150.0)))
  newEntity("p").attach(newLight(Point, position=vec(0.0, 0.2, 0.1), attenuation=vec(1.0, 0.0, 150.0)))

  info("World ok")


proc updateWorld*() =
  TheWorld.sun.getLight.position = vec(sin(Time.totalTime / 4.0)*5, 2, cos(Time.totalTime / 4.0)*5)