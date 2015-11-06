import logging
import math

import engine/vector
import engine/transform
import engine/messaging
import engine/ecs
import engine/camera
import engine/renderer/components

import game/world


type
  Game* = ref object
    listener: Listener

    world*: World

    cursor*: ivec3
    selection*: array[2, ivec3]
    selecting*: bool


var TheGame*: Game


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


proc updateGame*() =
  updateWorld()

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
