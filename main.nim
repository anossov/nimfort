import logging

addHandler(newConsoleLogger(fmtStr=verboseFmtStr))

import glfw/wrapper as glfw

import systems/windowing
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
  initInputSystem()
  initTimeSystem()
  initRenderSystem()
  initGUI()
  initWorld()


proc gameloop*() = 
  while glfw.windowShouldClose(Window) == 0:
    Time.update()
    TheWorld.update()
    UI.update()

    Renderer.render()

    glfw.swapBuffers(Window)
    glfw.pollEvents()

    if glfw.getKey(Window, glfw.KEY_W) == glfw.PRESS:
      Renderer.wire(true)
    else:
      Renderer.wire(false)


proc shutdown*() =
  shutdownWindow()


startup()
gameloop()
shutdown()