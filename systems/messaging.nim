import logging
import tables
import strutils


type
  Event* = tuple[name: string, payload: string]

  Listener* = ref object
    queue: seq[Event]
    iterating: bool
    buffer: seq[Event]

  MessageSystem* = ref object
    listeners: Table[string, seq[Listener]]


var Messages*: MessageSystem


proc newListener*(): Listener =
  result = Listener(
    queue: newSeq[Event](),
    buffer: newSeq[Event](),
  )


proc initMessageSystem*() =
  Messages = MessageSystem(
    listeners: initTable[string, seq[Listener]](),
  )
  info("Messaging ok")


proc listen*(listener: Listener, event: string) =
  if not Messages.listeners.hasKey(event):
    Messages.listeners[event] = newSeq[Listener]()
  Messages.listeners[event].add(listener)


proc enqueue(listener: Listener, event: Event) =
  if listener.iterating:
    listener.buffer.add(event)
  else:
    listener.queue.add(event)


proc emit*(m: MessageSystem, event: string, payload="") =
  debug(event, " ", payload)
  let parts = event.split('.')

  for i in -1..high(parts):
    let g = parts[0..i].join(".")
    if m.listeners.hasKey(g):
      for listener in mitems(m.listeners[g]):
        listener.enqueue((parts[high(parts)], payload))


iterator getMessages*(listener: var Listener): Event =
  listener.iterating = true
  for m in listener.queue:
    yield m
  listener.iterating = false
  listener.queue.setLen(0)
  listener.queue.add(listener.buffer)
  listener.buffer.setLen(0)


proc hasMessages*(listener: Listener): bool =
  listener.queue.len > 0
