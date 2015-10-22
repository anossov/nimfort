import logging
import tables


type
  Listener* = ref object
    queue: seq[string]

  MessageSystem* = ref object
    listeners: Table[string, seq[Listener]]
    groups: Table[string, seq[Listener]]


var Messages*: MessageSystem


proc newListener*(): Listener =
  result = Listener(
    queue: newSeq[string]()
  )


proc initMessageSystem*() =
  Messages = MessageSystem(
    listeners: initTable[string, seq[Listener]](),
    groups: initTable[string, seq[Listener]](),
  )
  info("Messaging ok")


proc listen*(listener: Listener, event: string) =
  if not Messages.listeners.hasKey(event):
    Messages.listeners[event] = newSeq[Listener]()
  Messages.listeners.mget(event).add(listener)

proc listenGroup*(listener: Listener, group: string) =
  if not Messages.groups.hasKey(group):
    Messages.groups[group] = newSeq[Listener]()
  Messages.groups.mget(group).add(listener)


proc emit*(m: MessageSystem, event: string, group="") =
  debug("$1 $2", group, event)
  if m.listeners.hasKey(event):
    for listener in mitems(m.listeners.mget(event)):
      listener.queue.add(event)

  if m.groups.hasKey(group):
    for listener in mitems(m.groups.mget(group)):
      listener.queue.add(event)

iterator getMessages*(listener: var Listener) =
  for m in listener.queue:
    yield m
  listener.queue.setLen(0)

proc hasMessages*(listener: Listener): bool =
  listener.queue.len > 0
