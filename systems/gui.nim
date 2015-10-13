import renderer
import text
import vector
import timekeeping
import messaging

type 
  GUI* = ref object
    R: RenderSystem
    messages: MessageSystem
    time: TimeSystem
    font: Font
    frametime: Text

    listener: Listener

proc newGUI*(m: MessageSystem, time: TimeSystem, r: RenderSystem): GUI =
  var f = loadFont("assets/liberationsans.fnt")
  result = GUI(
    time: time,
    messages: m,
    R: r,
    listener: newListener(),

    font: f,
    frametime: newText("", f, vec(1.0, 0.5, 0.0)),
  )

  result.messages.listen("frametime", result.listener)


proc update*(gui: GUI) =
  for e in gui.listener.queue:
    case e:
    of "frametime":
      gui.frametime.update($gui.time.mksPerFrame & " μs/frame")
    else:
      discard
  gui.listener.queue.setLen(0)

  gui.R.queue2d.add(Renderable(
    transform: newTransform(vec(30.0, gui.R.window.y, 0.0), zeroes3, vec(0.5, 0.5, 0.5)),
    mesh: gui.frametime.mesh
  ))