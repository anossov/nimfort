import tables

type
  Listener* = ref object
    queue*: seq[string]

  MessageSystem* = ref object
    listeners: Table[string, seq[Listener]]

proc newListener*(): Listener =
  result = Listener(
    queue: newSeq[string]()
  )

proc newMessageSystem*(): MessageSystem = 
  result = MessageSystem(
    listeners: initTable[string, seq[Listener]]()
  )

proc listen*(m: var MessageSystem, event: string, listener: Listener) = 
  if not m.listeners.hasKey(event):
    m.listeners[event] = newSeq[Listener]()
  m.listeners.mget(event).add(listener)

proc emit*(m: MessageSystem, event: string) =
  if m.listeners.hasKey(event):
    for listener in m.listeners[event]:
      listener.queue.add(event)