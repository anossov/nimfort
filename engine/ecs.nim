import logging
import tables
import typetraits
import strutils
import sequtils

import engine/messaging


type
  EntityHandle* = int32
  ComponentHandle* = int32

  Entity = object
    name: string
    components: Table[string, ComponentHandle]

  EntityManager = ref object
    entities: seq[Entity]
    listener: Listener

  Component* = object of RootObj
    entity*: EntityHandle

  ComponentStore*[T] = ref object
    name: string
    data*: seq[T]


var Entities*: EntityManager


proc initEntityManager*() =
  Entities = EntityManager(
    entities: newSeq[Entity](),
    listener: newListener(),
  )
  Entities.listener.listen("e")

proc newEntity*(name: string): EntityHandle =
  Entities.entities.add(Entity(
    name: name,
    components: initTable[string, ComponentHandle]()
  ))
  result = (len(Entities.entities) - 1).EntityHandle
  debug("$1 = $2".format(result, name))

proc addComponent*(em: EntityManager, e: EntityHandle, c: ComponentHandle, ctype: string) =
  em.entities[e].components[ctype] = c


proc `[]`*(e: EntityHandle, ctype: string): ComponentHandle =
  return Entities.entities[e].components[ctype]

proc exists*(e: EntityHandle): bool =
  return e >= 0 and e < Entities.entities.len

proc has*(e: EntityHandle, ctype: string): bool =
  return Entities.entities[e].components.hasKey(ctype)

proc name*(e: EntityHandle): string =
  return Entities.entities[e].name

proc listComponents*(e: EntityHandle): seq[string] =
  return toSeq(Entities.entities[e].components.keys)

proc newComponentStore*[T](): ComponentStore[T] =
  result = ComponentStore[T](
    name: name(T),
    data: newSeq[T]()
  )

proc add*[T](cs: ComponentStore[T], e: EntityHandle, c: T) =
  cs.data.add(c)
  let ch = (cs.data.len - 1).ComponentHandle
  cs.data[ch].entity = e
  Entities.addComponent(e, ch, cs.name)
  debug(" $1 +$2 $3".format(e, cs.name, ch))

proc `[]`*[T](cs: ComponentStore[T], e: EntityHandle): var T =
  assert e.has(cs.name)
  let ch = e[cs.name]
  return cs.data[ch]


template ImplementComponent*(Type: typedesc, accessor: expr) {.immediate.} =
  var `accessor Store` {.inject.} = newComponentStore[Type]()

  proc attach*(e: EntityHandle, c: Type): EntityHandle {.discardable.} =
    `accessor Store`.add(e, c)
    return e

  proc `accessor`*(e: EntityHandle): var Type {.inline.} =
    return `accessor Store`[e]

  proc `Type Store`*(): ComponentStore[Type] =
    return `accessor Store`


proc parseEntity*(pp: var PayloadParser): EntityHandle =
  result = pp.parseInt().EntityHandle
  if not result.exists:
    raise newException(ValueError, "No such entity: " & $result)


proc processECSMessages*() =
  for m in Entities.listener.getMessages():
    var p = m.parser()
    try:
      case m.name:

      of "name":
          Messages.emit("info", p.parseEntity().name)

      of "find":
        for i, e in Entities.entities:
          if e.name == m.payload:
            Messages.emit("info", $i)

      of "components":
        let e = p.parseEntity()
        Messages.emit("info", e.listComponents().join(", "))

      else: discard
    except ValueError:
      Messages.emit("error", getCurrentExceptionMsg())
