import tables
import logging
import strutils
import config

addHandler(newFileLogger("debug.log", fmtStr=verboseFmtStr, mode=fmWrite, levelThreshold=logLevel, bufSize=0))

import systems/windowing
import systems/ecs
import systems/gui
import systems/world
import systems/timekeeping
import systems/messaging
import systems/input
import systems/resources
import systems/camera
import systems/transform
import renderer/rendering


when defined(profiler) or defined(memProfiler):
  import nimprof


proc startup*() =
  initWindow()
  initMessageSystem()
  initEntityManager()
  initInputSystem()
  initTimeSystem()
  initResources()
  initCamera()
  initRenderSystem()
  initGUI()
  initWorld()


proc gameloop*() =
  var quit = newListener()
  quit.listen("quit")
  info("Loading complete in $1s".format(formatFloat(Time.now(), precision=3)))
  while true:
    if quit.hasMessages():
      break

    updateTime()
    updateInput()
    updateWorld()
    updateTransforms()
    updateCamera()
    updateUi()

    render()

    updateWindow()


proc shutdown*() =
  shutdownWindow()


startup()
gameloop()
shutdown()
