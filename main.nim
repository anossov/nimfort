import logging
import glfw/wrapper as glfw

import systems/renderer
import systems/gui
import systems/world
import systems/timekeeping
import systems/messaging

when defined(profiler) or defined(memProfiler):
  import nimprof

addHandler(newConsoleLogger(fmtStr=verboseFmtStr))

const
  windowWidth = 800
  windowHeight = 600
  windowTitle = "Nimfort"

if glfw.init() != 1:
  fatal("Failed to initialize GLFW")
  quit(0)

glfw.windowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
glfw.windowHint(glfw.CONTEXT_VERSION_MINOR, 0)
glfw.windowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
glfw.windowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
glfw.windowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)
glfw.windowHint(glfw.RESIZABLE, 0)
glfw.windowHint(glfw.REFRESH_RATE, 1000)
glfw.windowHint(glfw.SAMPLES, 4);

var win = glfw.createWindow(width=windowWidth, height=windowHeight, title=windowTitle, nil, nil)

glfw.makeContextCurrent(win)
glfw.swapInterval(0)

var 
  M = newMessageSystem()
  T = newTimeSystem(M)
  R = newRenderSystem(T, windowWidth, windowHeight)
  GUI = newGUI(M, T, R)
  W = newWorld(T, R)

while glfw.windowShouldClose(win) == 0:
  T.update()
  W.update()
  GUI.update()

  R.render()

  glfw.swapBuffers(win)
  glfw.pollEvents()

  if glfw.getKey(win, glfw.KEY_W) == glfw.PRESS:
    R.wire(true)
  else:
    R.wire(false)

glfw.destroyWindow(win)
glfw.terminate()