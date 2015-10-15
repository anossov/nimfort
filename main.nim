import tables
import logging

addHandler(newConsoleLogger(fmtStr=verboseFmtStr))

import systems/windowing
import systems/ecs
import systems/rendering
import systems/gui
import systems/world
import systems/timekeeping
import systems/messaging
import systems/input

when defined(profiler) or defined(memProfiler):
  import nimprof


proc startup*() = 
  initWindow()
  initMessageSystem()
  initEntityManager()
  initInputSystem()
  initTimeSystem()
  initRenderSystem()
  initGUI()
  initWorld()


proc gameloop*() = 
  var quit = newListener()
  Messages.listen("quit", quit)

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