import logging
import text
import vector

import systems/messaging
import systems/rendering
import systems/timekeeping


type
  GUI* = ref object
    font: Font
    frametime: Text

    listener: Listener


var UI*: GUI


proc initGUI*()=
  var f = loadFont("assets/liberationsans.fnt")
  UI = GUI(
    listener: newListener(),

    font: f,
    frametime: newText("", f, vec(1.0, 0.5, 0.0)),
  )

  Messages.listen("frametime", UI.listener)

  info("UI ok")


proc updateUi*() =
  for e in UI.listener.queue:
    case e:
    of "frametime":
      UI.frametime.update($Time.mksPerFrame & " μs/frame")
    else:
      discard
  UI.listener.queue.setLen(0)

  Renderer.queue2d.add(Renderable(
    transform: newTransform(vec(30.0, Renderer.windowSize.y, 0.0), zeroes3, vec(0.5, 0.5, 0.5)),
    mesh: UI.frametime.mesh
  ))