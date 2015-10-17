import logging

import tables
import text
import vector

import systems/ecs
import systems/messaging
import systems/resources
import systems/timekeeping
import renderer/components
import renderer/rendering


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
  t.entity.attach(Label(transform: transform, color: vec(0.5, 0.5, 0.5), mesh: m.mesh, texture: ui.font.textures[0]))
  ui.texts[name] = t


proc update(t: var Text, s: string) = 
  t.mesh.update(s)
  t.entity.getLabel().mesh = t.mesh.mesh


proc initGUI*()=
  UI = GUI(
    listener: newListener(),
    font: Resources.getFont("liberationsans"),
    texts: initTable[string, Text]()
  )

  UI.newText("frametime", newTransform(vec(30.0, Renderer.windowSize.y, 0.0), zeroes3, vec(0.5, 0.5, 0.5)))

  Messages.listen("frametime", UI.listener)

  info("UI ok")


proc updateUi*() =
  for e in UI.listener.queue:
    case e:
    of "frametime":
      UI.texts.mget("frametime").update($Time.mksPerFrame & " μs/frame")
    else:
      discard
  UI.listener.queue.setLen(0)