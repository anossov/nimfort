import logging
import strutils
import unicode

import tables
import text
import vector

import systems/ecs
import systems/messaging
import systems/resources
import systems/timekeeping
import systems/camera
import systems/transform
import renderer/components
import renderer/rendering
import renderer/screen


type
  GUI* = ref object
    font: Font

    texts: Table[string, EntityHandle]

    consoleLines: seq[EntityHandle]
    topLine: int
    charListener: Listener
    keyListener: Listener
    errorListener: Listener
    infoListener: Listener


var UI*: GUI

const
  textScale = 0.5
  textColor = vec(0.5, 0.5, 0.5, 1.0)


proc newText(ui: var GUI, name: string, x, y: float32; text="", color=textColor, scale=textScale): EntityHandle =
  var ox = 0.0
  var oy = 0.0

  if x < 0.0: ox = Screen.size[0]
  if y < 0.0: oy = Screen.size[1]

  let
    m = ui.font.newTextMesh(text)
    e = newEntity("ui-text-" & name)
    t = newTransform(p=vec(ox + x, oy + y, 0.0), s=scale)

  e.attach(Label(text: text, color: color, mesh: m, texture: ui.font.textures[0]))
  e.attach(t)

  return e

proc addText(ui: var GUI, name: string, x, y: float32; text="", color=textColor, scale=textScale) =
  ui.texts[name] = ui.newText(name, x, y, text, color, scale)

proc initGUI*()=
  UI = GUI(
    charListener: newListener(),
    keyListener: newListener(),
    errorListener: newListener(),
    infoListener: newListener(),
    font: getFont("liberationsans"),
    texts: initTable[string, EntityHandle](),
    consoleLines: newSeq[EntityHandle](),
  )

  UI.addText("frametime", 30.0, -10.0)
  UI.addText("console", 30.0, 50.0)

  for i in 1..10:
    let f = i.float
    let e = UI.newText("console-line-" & $i, 30.0, 50.0 + f*30.0)
    UI.consoleLines.add(e)
    UI.topLine = i

  UI.charListener.listen("input.char")
  UI.keyListener.listen("input")
  UI.errorListener.listen("error")
  UI.infoListener.listen("info")

  info("UI ok")

proc consoleAdd(ui: GUI, text: string, color=textColor) =
  let n = len(UI.consoleLines)
  UI.topLine = (UI.topLine + n - 1) mod n

  var newLine = UI.consoleLines[UI.topLine]
  newLine.transform.position = vec(30.0, 50.0, 0.0)
  newLine.transform.updateMatrix()
  newLine.label.update(text)
  newLine.label.color = color
  newLine.label.fade = true
  newLine.label.fadeTime = 10.0

  for i, line in ui.consoleLines:
    let h = (n + i - UI.topLine) mod n + 1
    line.transform.animate(p=vec(30.0, 50.0 + h.float * 30.0, 0.0), duration=0.1)

proc updateUi*() =
  UI.texts["frametime"].label.update("$1 μs/frame ($2 fps)".format(Time.mksPerFrame, Time.fps.int))

  var console = UI.texts["console"]
  let t = console.label.text

  for e in UI.charListener.getMessages():
    try:
      if e.len > 8:
        raise newException(ValueError, "")
      let c = e.parseHexInt.Rune.toUTF8
      console.label.update(t & c)
    except ValueError:
      Messages.emit("error.Invalid character code: " & e)

  for k in UI.keyListener.getMessages():
    case k:
    of "ENTER-down", "KP_ENTER-down":
      if t == "": continue

      Messages.emit(t)
      console.label.update("")
      UI.consoleAdd(t)

    of "BACKSPACE-down", "BACKSPACE-repeat":
      console.label.update(t[0..high(t)-1])
    else: discard

  for e in UI.errorListener.getMessages():
    UI.consoleAdd(e, vec(1.0, 0.1, 0.1, 1.0))

  for e in UI.infoListener.getMessages():
    UI.consoleAdd(e, vec(0.1, 0.6, 0.1, 1.0))
