import logging
import mesh
import gl/texture
import objfile
import vector
import mersenne
import times
import math

import systems/ecs
import systems/rendering

type
  World* = ref object
    discard


var TheWorld*: World


proc initWorld*() =
  var data = loadObj("assets/bird/bird_decoration.obj")
  var mesh = newMesh(data, newTexture("assets/bird/bird_decoration_diffuse1024.png"))

  var e = newEntity("bird")
  e.attach(Renderable3d(transform: newTransform(zeroes3, zeroes3, ones3), mesh: mesh))
  
  TheWorld = World()

  info("World ok")


proc updateWorld*() =
  discard