import tables
import logging
import strutils

import config

addHandler(newFileLogger("debug.log", fmtStr=verboseFmtStr, mode=fmWrite, levelThreshold=logLevel, bufSize=0))

import engine/windowing
import engine/ecs
import engine/timekeeping
import engine/messaging
import engine/input
import engine/resources
import engine/camera
import engine/transform
import engine/renderer/rendering

import game/gui
import game/game


when defined(profiler) or defined(memProfiler):
  import nimprof


proc startup*() =
  initWindow()
  initMessageSystem()
  initTimeSystem()
  initEntityManager()
  initInputSystem()
  initResources()
  initRenderSystem()
  initCamera()
  initGame()
  initGUI()


proc gameloop*() =
  var quit = newListener()
  quit.listen("quit")
  info("Loading complete in $1s".format(formatFloat(Time.now(), precision=3)))
  while true:
    if quit.hasMessages():
      break

    updateTime()
    updateTransforms()
    render()

    updateWindow()


proc shutdown*() =
  shutdownWindow()


startup()
gameloop()
shutdown()
