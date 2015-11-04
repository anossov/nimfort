import logging
import math

import engine/vector
import engine/transform
import engine/messaging
import engine/ecs
import engine/camera


type
  Game* = ref object
    listener: Listener
    cursor*: ivec3
    selection*: array[2, ivec3]
    selecting*: bool


var TheGame*: Game


proc initGame*() =
  TheGame = Game(
    listener: newListener(),
  )
  TheGame.listener.listen("game")


proc updateGame*() =
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
