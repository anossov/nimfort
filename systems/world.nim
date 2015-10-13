import logging
import renderer
import mesh
import gl/texture
import objfile
import vector
import timekeeping
import mersenne
import times
import math

type
  World = ref object
    R: RenderSystem
    time: TimeSystem
    things: seq[Renderable]


proc newWorld*(time: TimeSystem, r: RenderSystem): World =
  info("World init start")
  var data = loadObj("assets/bird/bird_decoration.obj")
  var mesh = newMesh(data, newTexture("assets/bird/bird_decoration_diffuse1024.png"))
  
  result = World(
    R: r,
    time: time,
    things: newSeq[Renderable](),
  )
 
  result.things.add(Renderable(transform: newTransform(zeroes3, zeroes3, ones3), mesh: mesh))

  info("World init end")

proc update*(w: World) =
  for t in w.things:
    w.R.queue3d.add(t)