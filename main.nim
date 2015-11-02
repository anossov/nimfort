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
import game/world
import game/game


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
  initCamera()
  initGame()
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
    processECSMessages()
    updateInput()
    updateWorld()
    updateGame()
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
