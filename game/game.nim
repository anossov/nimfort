import logging
import math
import random
import tables

import engine/vector
import engine/transform
import engine/messaging
import engine/ecs
import engine/camera
import engine/timekeeping
import engine/resources
import engine/renderer/components


import game/world


type
  Game* = ref object
    listener: Listener

    world*: World

    cursor*: ivec3
    selection*: array[2, ivec3]
    selecting*: bool

  AI* = object of Component
    worldPos: ivec3

ImplementComponent(AI, ai)


var TheGame*: Game


proc updateGame*() =
  TheGame.world.updateWorld()

  let p = Camera.pickGround(-0.5) + vec(0, 0.5, 0)
  TheGame.cursor = ivec(p.x.round, p.y.round, p.z.round)

  for m in TheGame.listener.getMessages():
    var p = m.parser()
    try:
      case m.name:

      of "move":
        let e = p.parseEntity()
        if e.has(CTransform):
          e.transform.position = TheGame.cursor.toFloat()
          e.transform.updateMatrix()

      of "selection-start":
        TheGame.selection[0] = TheGame.cursor
        TheGame.selecting = true

      of "selection-end":
        TheGame.selecting = false

      else: discard

    except ValueError:
      Messages.emit("error", getCurrentExceptionMsg())

  if TheGame.selecting:
    TheGame.selection[1] = TheGame.cursor

proc tick*() =
  for e in mitems(aiStore.data):
    let
      p = e.worldPos
      c = TheGame.cursor
      d = c - p
    if d == ivec(0, 0, 0): continue

    var dir: ivec3
    if d.x.abs > d.z.abs:
      if d.x < 0: dir = ivec(-1, 0, 0)
      else: dir = ivec(1, 0, 0)
    else:
      if d.z < 0: dir = ivec(0, 0, -1)
      else: dir = ivec(0, 0, 1)

    var move = true
    for o in TheGame.world.objectsAt(p + dir):
      if o.pos == p + dir:
        move = false
        break

    if move:
      e.worldPos = p + dir
      e.entity.transform.animate(e.worldPos.toFloat, 0.1)

proc initGame*() =
  TheGame = Game(
    listener: newListener(),
    world: newWorld()
  )
  TheGame.listener.listen("game")

  newEntity("light-sun")
    .attach(newTransform(f=vec(3, -11, -4.4), p=vec(-3, 5, 5), u=yaxis))
    .attach(newDirLight(color=vec(5, 5, 5), shadows=true))

  newEntity("light-ambient").attach(newAmbientCube(
    posx=vec(0.01, 0.02, 0.01),
    negx=vec(0.01, 0.02, 0.01),
    posy=vec(0.03, 0.04, 0.05),
    negy=vec(0.01, 0.0, 0.0),
    posz=vec(0.01, 0.02, 0.1),
    negz=vec(0.01, 0.02, 0.01),
  ))

  newEntity("b")
    .attach(newTransform(p=vec(3, 0, 3), s=0.4))
    .attach(newModel(
        getMesh("ball"),
        albedo=getColorTexture(vec(1.0, 0.0, 0.0, 1.0)),
        roughness=getColorTexture(vec(0.9, 0.9, 0.9, 1.0))
    ))
    .attach(Bounce(min: 0.3, max: 0.5, period: 2.0))
    .attach(AI(worldPos: ivec(3, 0, 3)))

  Time.schedule(updateGame, hz=60)
  Time.schedule(tick, hz=10)
