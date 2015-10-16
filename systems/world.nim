import logging
import mesh
import gl/texture
import objfile
import vector
import times
import strutils

import systems/ecs
import systems/resources
import renderer/rendering
import renderer/components

type
  World* = ref object
    discard


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

  info("World ok")


proc updateWorld*() =
  discard