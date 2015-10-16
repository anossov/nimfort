import tables
import logging
import strutils

addHandler(newConsoleLogger(fmtStr=verboseFmtStr))

import systems/windowing
import systems/ecs
import systems/gui
import systems/world
import systems/timekeeping
import systems/messaging
import systems/input
import systems/resources
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
  initRenderSystem()
  initGUI()
  initWorld()


proc gameloop*() = 
  var quit = newListener()
  Messages.listen("quit", quit)
  info("Loading complete in $1s", formatFloat(Time.now(), precision=3))
  while true:
    if len(quit.queue) > 0:
      break

    updateTime()
    updateWorld()
    updateUi()

    render()

    updateWindow()


proc shutdown*() =
  shutdownWindow()


startup()
gameloop()
shutdown()