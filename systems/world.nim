import logging
import mesh
import gl/texture
import objfile
import vector
import mersenne
import times
import math

import systems/rendering

type
  World* = ref object
    things: seq[Renderable]


var TheWorld*: World


proc initWorld*() =
  var data = loadObj("assets/bird/bird_decoration.obj")
  var mesh = newMesh(data, newTexture("assets/bird/bird_decoration_diffuse1024.png"))
  
  TheWorld = World(
    things: newSeq[Renderable](),
  )
 
  TheWorld.things.add(Renderable(transform: newTransform(zeroes3, zeroes3, ones3), mesh: mesh))

  info("World ok")


proc update*(w: World) =
  for t in w.things:
    Renderer.queue3d.add(t)