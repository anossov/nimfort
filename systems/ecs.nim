import logging
import tables
import typetraits

type
  EntityHandle* = int32
  ComponentHandle* = int32

  Entity = object
    name: string
    components: Table[string, ComponentHandle]

  EntityManager = ref object
    entities: seq[Entity]

  Component* = object of RootObj
    entity*: EntityHandle

  ComponentStore*[T] = ref object
    name: string
    data*: seq[T]


var Entities*: EntityManager


proc initEntityManager*() =
  Entities = EntityManager(
    entities: newSeq[Entity](),
  )

proc newEntity*(name: string): EntityHandle = 
  Entities.entities.add(Entity(
    name: name,
    components: initTable[string, ComponentHandle]()
  ))
  result = (len(Entities.entities) - 1).EntityHandle
  debug("NE: $1 = $2", name, result)

proc addComponent*(em: EntityManager, e: EntityHandle, c: ComponentHandle, ctype: string) = 
  debug("NC: $1 <- $2", e, ctype)
  em.entities[e].components[ctype] = c


proc `[]`*(e: EntityHandle, ctype: string): ComponentHandle =
  return Entities.entities[e].components[ctype]

proc has(e: EntityHandle, ctype: string): bool = 
  return Entities.entities[e].components.hasKey(ctype)

proc newComponentStore*[T](): ComponentStore[T] = 
  result = ComponentStore[T](
    name: name(T),
    data: newSeq[T]()
  )

proc add*[T](cs: ComponentStore[T], e: EntityHandle, c: T) =
  cs.data.add(c)
  let ch = (cs.data.len - 1).ComponentHandle
  
  Entities.addComponent(e, ch, cs.name)

proc `[]`*[T](cs: ComponentStore[T], e: EntityHandle): var T =
  assert e.has(cs.name)
  return cs.data[e[cs.name]]