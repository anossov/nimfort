import logging
import glfw/wrapper as glfw

import systems/messaging


type
  TimeSystem* = ref object
    totalTime*: float
    delta*: float
    prevTime: float

    mksPerFrame*: int
    ftLastUpdate: float
    ftCounter: int


var Time*: TimeSystem


proc initTimeSystem*() =
  Time = TimeSystem()
  info("Timers ok")

proc now*(t: TimeSystem): float = glfw.getTime()

proc fps*(t: TimeSystem): float = 1_000_000 / t.mksPerFrame

proc updateTime*() =
  let t = Time
  t.totalTime = t.now()
  t.delta = t.totalTime - t.prevTime
  t.prevTime = t.totalTime

  if t.totalTime - t.ftLastUpdate > 0.5 and t.ftCounter > 0:
    t.mksPerFrame = int((t.totalTime - t.ftLastUpdate) * 1_000_000 / t.ftCounter.float)
    t.ftLastUpdate = t.totalTime
    t.ftCounter = 0

  t.ftCounter += 1
