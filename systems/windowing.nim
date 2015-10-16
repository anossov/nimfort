import logging
import glfw/wrapper as glfw
import vector
import systems/messaging
import config

var Window*: GLFWwindow


proc windowSize*(): vec2 =
  var x, y: cint
  glfw.getWindowSize(Window, x.addr, y.addr)
  result = [x.float32, y.float32]


proc initWindow*() = 
  if glfw.init() != 1:
    fatal("Failed to initialize GLFW")
    quit(0)

  glfw.windowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
  glfw.windowHint(glfw.CONTEXT_VERSION_MINOR, 0)
  glfw.windowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  glfw.windowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
  glfw.windowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)
  glfw.windowHint(glfw.RESIZABLE, 0)
  glfw.windowHint(glfw.SAMPLES, MSAASamples)

  Window = glfw.createWindow(width=windowWidth, height=windowHeight, title=windowTitle, nil, nil)

  glfw.makeContextCurrent(Window)
  glfw.swapInterval(0)

  info("Window ok: $1x$2", windowWidth, windowHeight)


proc updateWindow*() =
  glfw.swapBuffers(Window)
  glfw.pollEvents()

  if glfw.windowShouldClose(Window) == 1:
    Messages.emit("quit")


proc shutdownWindow*() =
  glfw.destroyWindow(Window)
  glfw.terminate()
  info("Window shut down")