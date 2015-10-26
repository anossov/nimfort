import logging
import strutils

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

  Text = object of Component
    mesh: TextMesh

var UI*: GUI


proc newText(ui: GUI, name: string, transform: Transform, s: string = "") =
  let
    m = ui.font.newTextMesh(s)
    e = newEntity("ui-text-" & name)
    t = Text(entity: e, mesh: m)
  t.entity.attach(Label(color: vec(0.5, 0.5, 0.5), mesh: m.mesh, texture: ui.font.textures[0]))
  t.entity.attach(transform)
  ui.texts[name] = t


proc update(t: var Text, s: string) =
  t.mesh.update(s)
  t.entity.label.mesh = t.mesh.mesh


proc initGUI*()=
  UI = GUI(
    listener: newListener(),
    font: getFont("liberationsans"),
    texts: initTable[string, Text]()
  )

  UI.newText("frametime", newTransform(p=vec(30.0, Screen.size.y - 10.0, 0.0), s=0.5))
  UI.listener.listen("frametime")

  info("UI ok")


proc updateUi*() =
  for e in UI.listener.getMessages():
    case e:
    of "frametime":
      UI.texts.mget("frametime").update($Time.mksPerFrame & " μs/frame (" & $((1000000 / Time.mksPerFrame).int) & " fps)")
    else:
      discard
