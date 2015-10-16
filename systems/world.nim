import logging
import mesh
import gl/texture
import objfile
import vector
import times
import strutils

import systems/ecs
import systems/rendering
import systems/resources

type
  World* = ref object
    discard


var TheWorld*: World


proc initWorld*() =
  var mesh = Resources.getModel("head")
  var p = Resources.getModel("quad", false)
  
  let e = newEntity("bird")
  let ep = newEntity("ground")
  let t = Resources.getTexture("test")
  p.texture = t
  mesh.normalmap = Resources.getTexture("headN", false)
  mesh.specularmap = Resources.getTexture("headS", false)
  
  e.attach(Renderable3d(transform: newTransform(zeroes3, zeroes3, ones3 * 0.05), mesh: mesh))
  ep.attach(Renderable3d(transform: newTransform(vec(0.0, -1.0, 0.0), zeroes3, ones3 * 20.0), mesh: p))
  
  
  TheWorld = World()

  info("World ok")


proc updateWorld*() =
  discard