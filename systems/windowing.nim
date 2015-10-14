import logging
import glfw/wrapper as glfw
import vector

const
  windowWidth = 800
  windowHeight = 600
  windowTitle = "Nimfort"


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
  glfw.windowHint(glfw.SAMPLES, 4)

  Window = glfw.createWindow(width=windowWidth, height=windowHeight, title=windowTitle, nil, nil)

  glfw.makeContextCurrent(Window)
  glfw.swapInterval(0)


proc shutdownWindow*() =
  glfw.destroyWindow(Window)
  glfw.terminate()