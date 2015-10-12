import renderer
import text
import vector


type 
  GUI* = ref object
    R: RenderSystem
    font: Font
    frametime: Text
    ftCounter: int
    ftLastUpdate: float

proc newGUI*(r: RenderSystem): GUI =
  var f = loadFont("assets/liberationsans.fnt")
  result = GUI(
    R: r,
    font: f,
    frametime: newText("", f, [1.0'f32, 0.5, 0.0]),
  )


proc update*(gui: GUI, time, delta: float) =
  if time - gui.ftLastUpdate > 1.0 and gui.ftCounter > 0:
    let mkspf = int((time - gui.ftLastUpdate) * 1_000_000 / gui.ftCounter.float)
    gui.frametime.update($mkspf & " μs/frame")
    gui.ftLastUpdate = time
    gui.ftCounter = 0
  gui.ftCounter += 1

  gui.R.queue2d.add(Renderable(
    transform: newTransform([30.0'f32, gui.R.window.y, 0.0], zero, [0.5'f32, 0.5, 0.5]),
    mesh: gui.frametime.mesh
  ))