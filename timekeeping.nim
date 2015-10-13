import glfw/wrapper as glfw
import messaging

type
  TimeSystem* = ref object
    totalTime*: float
    delta*: float
    prevTime: float

    messages: MessageSystem

    mksPerFrame*: int
    ftLastUpdate: float
    ftCounter: int

proc newTimeSystem*(m: MessageSystem): TimeSystem =
  result = TimeSystem(
    messages: m,
  )

proc update*(t: TimeSystem) =
  t.totalTime = glfw.getTime()
  t.delta = t.totalTime - t.prevTime
  t.prevTime = t.totalTime

  if t.totalTime - t.ftLastUpdate > 0.5 and t.ftCounter > 0:
    t.mksPerFrame = int((t.totalTime - t.ftLastUpdate) * 1_000_000 / t.ftCounter.float)
    t.ftLastUpdate = t.totalTime
    t.ftCounter = 0
    t.messages.emit("frametime")

  t.ftCounter += 1