import logging
import strutils
import unicode
import math
import tables

import engine/text
import engine/mesh
import engine/vector
import engine/ecs
import engine/messaging
import engine/resources
import engine/timekeeping
import engine/input
import engine/transform
import engine/renderer/components
import engine/renderer/screen

import game/game
import game/world


type
  GUI* = ref object
    font: Font

    texts: Table[string, EntityHandle]

    consoleLines: seq[EntityHandle]
    topLine: int
    consoleListener: Listener
    consoleHistory: seq[string]
    consoleHistoryP: int
    cursor: EntityHandle
    selection: EntityHandle

    debug: bool


var UI*: GUI

const
  textScale  = 0.4
  textColor  = vec(0.9, 0.9, 0.9, 1.0)
  debugColor = vec(0.9, 0.9, 0.4, 1.0)
  errorColor = vec(1.0, 0.1, 0.1, 1.0)
  infoColor  = vec(0.1, 1.0, 0.1, 1.0)

  cursorColor    = vec(1, 1, 1, 0.5)
  selectionColor = vec(0.9, 0.0, 0.9, 0.3)

  paddingLeft           = 30.0
  paddingTop            = -20.0
  lineHeight            = 30.0
  consolePos            = vec(paddingLeft, 50.0)
  consoleFadeTime       = 10.0
  consoleScrollDuration = 0.1


proc newText(ui: var GUI, name: string, x, y: float32; text="", align=AlignLeft, color=textColor, scale=textScale): EntityHandle =
  var ox = 0.0
  var oy = 0.0

  if x < 0.0: ox = Screen.size[0]
  if y < 0.0: oy = Screen.size[1]

  let
    m = ui.font.newTextMesh(text)
    e = newEntity("ui-text-" & name)
    t = newTransform(p=vec(ox + x, oy + y, 0.0), s=scale)

  e.attach(Label(text: text, color: color, mesh: m, align: align, texture: ui.font.textures[0]))
  e.attach(t)

  return e

proc addText(ui: var GUI, name: string, x, y: float32; text="", align=AlignLeft, color=textColor, scale=textScale) =
  ui.texts[name] = ui.newText(name, x, y, text, align, color, scale)

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


proc updateConsole*() =
  var console = UI.texts["console"]
  let t = console.label.text

  for e in UI.consoleListener.getMessages():
    case e.name:
    of "char":
      try:
        if e.payload.len > 8:
          raise newException(ValueError, "Character code too long")
        let c = e.payload.parseHexInt.Rune.toUTF8
        console.label.update(t & c)
      except ValueError:
        Messages.emit("error", getCurrentExceptionMsg())

    of "history-back":
      if UI.consoleHistory.len > 0 and UI.consoleHistoryP > 0:
        UI.consoleHistoryP -= 1
        console.label.update(UI.consoleHistory[UI.consoleHistoryP])

    of "history-forward":
      if UI.consoleHistory.len > 0 and UI.consoleHistoryP < UI.consoleHistory.high:
        UI.consoleHistoryP += 1
        console.label.update(UI.consoleHistory[UI.consoleHistoryP])

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
      if UI.consoleHistory.len == 0 or UI.consoleHistory[UI.consoleHistory.high] != t:
        UI.consoleHistory.add(t)
      UI.consoleHistoryP = UI.consoleHistory.len

    of "erase":
      console.label.update(t[0..high(t)-1])

    of "debug-info":
      UI.debug = not UI.debug

    else: discard

proc updateDebugText() =
  if UI.debug:
    UI.texts["frametime"].label.update("$1 μs/frame ($2 fps)".format(Time.mksPerFrame, Time.fps.int))
    UI.texts["meshes"].label.update("Meshes rendered: $1".format(meshesRendered))
  else:
    UI.texts["frametime"].label.update("")
    UI.texts["meshes"].label.update("")


proc updateOverlays() =
  UI.cursor.transform.position = vec(TheGame.cursor.x.float, TheGame.cursor.y.float, TheGame.cursor.z.float)
  UI.cursor.transform.updateMatrix()

  let
    a = TheGame.selection[0].toFloat()
    b = TheGame.selection[1].toFloat()
    ss = abs(a - b) + 1
  UI.selection.transform.position = (a + b) * 0.5
  UI.selection.transform.position.y -= 0.5
  UI.selection.transform.scale.x = ss.x + 0.05
  UI.selection.transform.scale.z = ss.z + 0.05
  UI.selection.transform.updateMatrix()

  let c = TheGame.world.chunkWith(TheGame.cursor.xz)
  var o = ""
  for i in c.objects:
    if i.pos == TheGame.cursor.xz:
      o = i.entity.name & " at "
      break
  UI.texts["cursor-pos"].label.update("$3$1, chunk $2".format(TheGame.cursor, c.pos, o))
  UI.texts["selection"].label.update("$1 × $2".format(ss.x.int, ss.z.int))


proc initGUI*()=
  UI = GUI(
    consoleListener: newListener(),
    font: getFont("liberationsans"),
    texts: initTable[string, EntityHandle](),
    consoleLines: newSeq[EntityHandle](),
    consoleHistory: newSeq[string](),
  )

  UI.addText("cursor-pos", -paddingLeft, paddingTop, align=AlignRight)
  UI.addText("selection", -paddingLeft, paddingTop - lineHeight, align=AlignRight)
  UI.addText("frametime", paddingLeft, paddingTop, color=debugColor)
  UI.addText("meshes", paddingLeft, paddingTop - lineHeight, color=debugColor)
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
  UI.consoleListener.listen("gui")

  UI.cursor = newEntity("cursor")
  UI.cursor.attach(newTransform())
  UI.cursor.attach(Overlay(mesh: getMesh("cursor"), color: cursorColor))

  UI.selection = newEntity("selection")
  UI.selection.attach(newTransform(s=vec(1, 0.1, 1)))
  UI.selection.attach(Overlay(mesh: getMesh("cube"), color: selectionColor))

  Input.hideCursor()

  Time.schedule(updateConsole, hz=60)
  Time.schedule(updateDebugText, hz=10)
  Time.schedule(updateOverlays, hz=60)

  info("UI ok")
