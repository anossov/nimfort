import logging
import tables
import strutils


type
  Listener* = ref object
    queue: seq[string]
    iterating: bool
    buffer: seq[string]

  MessageSystem* = ref object
    listeners: Table[string, seq[Listener]]

var Messages*: MessageSystem


proc newListener*(): Listener =
  result = Listener(
    queue: newSeq[string](),
    buffer: newSeq[string](),
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


proc enqueue(listener: Listener, event: string) =
  if listener.iterating:
    listener.buffer.add(event)
  else:
    listener.queue.add(event)


proc emit*(m: MessageSystem, event: string) =
  debug(event.replace("$", "$$"))
  let parts = event.split('.')

  for i in -1..high(parts):
    let g = parts[0..i].join(".")
    if m.listeners.hasKey(g):
      for listener in mitems(m.listeners[g]):
        listener.enqueue(parts[high(parts)])

iterator getMessages*(listener: var Listener): string =
  listener.iterating = true
  for m in listener.queue:
    yield m
  listener.iterating = false
  listener.queue.setLen(0)
  listener.queue.add(listener.buffer)
  listener.buffer.setLen(0)

proc hasMessages*(listener: Listener): bool =
  listener.queue.len > 0
