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
  var mesh = Resources.getModel("bird")
  var p = Resources.getModel("quad", false)
  var c = Resources.getModel("cube", false)
  let e = newEntity("bird")
  let ep = newEntity("ground")
  let ec = newEntity("cube")
  let t = Resources.getTexture("test")
  p.texture = t
  c.texture = t

  mesh.normalmap = Resources.getTexture("normaltest", false)

  e.attach(Renderable3d(transform: newTransform(zeroes3, zeroes3, ones3 * 0.4), mesh: mesh))
  ep.attach(Renderable3d(transform: newTransform(vec(0.0, -1.0, 0.0), zeroes3, ones3 * 20.0), mesh: p))
  ec.attach(Renderable3d(transform: newTransform(vec(-1, -0.8, 1.0), zeroes3, ones3 * 0.2), mesh: c))
  
  TheWorld = World()

  info("World ok")


proc updateWorld*() =
  discard