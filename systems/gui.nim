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

    texts: Table[string, Text]

    listener: Listener
    charListener: Listener
    keyListener: Listener

  Text = object
    text: string
    entity: EntityHandle
    mesh: TextMesh

var UI*: GUI


proc newText(ui: GUI, name: string, transform: Transform, s: string = "") =
  let
    m = ui.font.newTextMesh(s)
    e = newEntity("ui-text-" & name)
    t = Text(entity: e, mesh: m, text: s)
  t.entity.attach(Label(color: vec(0.5, 0.5, 0.5), mesh: m.mesh, texture: ui.font.textures[0]))
  t.entity.attach(transform)
  ui.texts[name] = t


proc update(t: var Text, s: string) =
  t.text = s
  t.mesh.update(s)
  t.entity.label.mesh = t.mesh.mesh


proc initGUI*()=
  UI = GUI(
    listener: newListener(),
    charListener: newListener(),
    keyListener: newListener(),
    font: getFont("liberationsans"),
    texts: initTable[string, Text]()
  )

  UI.newText("frametime", newTransform(p=vec(30.0, Screen.size.y - 10.0, 0.0), s=0.5))
  UI.newText("console", newTransform(p=vec(30.0, 50.0, 0.0), s=0.5))

  UI.listener.listen("frametime")
  UI.charListener.listen("input.char")
  UI.keyListener.listen("input")

  info("UI ok")


proc updateUi*() =
  for e in UI.listener.getMessages():
    case e:
    of "frametime":
      UI.texts.mget("frametime").update($Time.mksPerFrame & " μs/frame (" & $((1000000 / Time.mksPerFrame).int) & " fps)")
    else: discard

  for e in UI.charListener.getMessages():
    let t = UI.texts["console"].text
    let c = e.parseHexInt.Rune.toUTF8
    UI.texts.mget("console").update(t & c)

  for k in UI.keyListener.getMessages():
    let t = UI.texts["console"].text
    case k:
    of "ENTER-down":
      Messages.emit(t)
      UI.texts.mget("console").update("")
    of "BACKSPACE-down", "BACKSPACE-repeat":
      UI.texts.mget("console").update(t[0..high(t)-1])
    else: discard
