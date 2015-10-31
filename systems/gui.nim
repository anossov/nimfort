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
    consoleListener: Listener


var UI*: GUI

const
  textScale  = 0.5
  textColor  = vec(0.5, 0.5, 0.5, 1.0)
  errorColor = vec(1.0, 0.1, 0.1, 1.0)
  infoColor  = vec(0.1, 0.6, 0.1, 1.0)

  paddingLeft           = 30.0
  paddingTop            = -20.0
  lineHeight            = 30.0
  consolePos            = vec(paddingLeft, 50.0)
  consoleFadeTime       = 10.0
  consoleScrollDuration = 0.1


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
    consoleListener: newListener(),
    font: getFont("liberationsans"),
    texts: initTable[string, EntityHandle](),
    consoleLines: newSeq[EntityHandle](),
  )

  UI.addText("frametime", paddingLeft, paddingTop)
  UI.addText("console", consolePos.x, consolePos.y)

  for i in 1..10:
    let f = i.float
    let e = UI.newText("console-line-" & $i, consolePos.x, consolePos.y + f * lineHeight)
    UI.consoleLines.add(e)
    UI.topLine = i

  UI.consoleListener.listen("input.char")
  UI.consoleListener.listen("error")
  UI.consoleListener.listen("info")
  UI.consoleListener.listen("console")

  info("UI ok")

proc consoleAdd(ui: GUI, text: string, color=textColor) =
  let n = len(UI.consoleLines)
  UI.topLine = (UI.topLine + n - 1) mod n

  var newLine = UI.consoleLines[UI.topLine]
  newLine.transform.position = vec(consolePos.x, consolePos.y, 0.0)
  newLine.transform.updateMatrix()
  newLine.label.update(text)
  newLine.label.color = color
  newLine.label.fade = true
  newLine.label.fadeTime = consoleFadeTime

  for i, line in ui.consoleLines:
    let h = (n + i - UI.topLine) mod n + 1
    line.transform.animate(p=vec(consolePos.x, consolePos.y + h.float * lineHeight, 0.0), duration=consoleScrollDuration)

proc updateUi*() =
  UI.texts["frametime"].label.update("$1 μs/frame ($2 fps)".format(Time.mksPerFrame, Time.fps.int))

  var console = UI.texts["console"]
  let t = console.label.text

  for e in UI.consoleListener.getMessages():
    case e.name:
    of "char":
      try:
        if e.payload.len > 8:
          raise newException(ValueError, "")
        let c = e.payload.parseHexInt.Rune.toUTF8
        console.label.update(t & c)
      except ValueError:
        Messages.emit("error", "Invalid character code: " & e.payload)

    of "info":
      UI.consoleAdd(e.payload, infoColor)

    of "error":
      UI.consoleAdd(e.payload, errorColor)

    of "submit":
      if t == "": continue
      let space = t.find(' ')
      if space != -1:
        Messages.emit(t[0..space.pred], t[space.succ..t.high])
      else:
        Messages.emit(t)
      console.label.update("")
      UI.consoleAdd(t)

    of "erase":
      console.label.update(t[0..high(t)-1])

    else: discard
