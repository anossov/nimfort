import logging
import messaging
import glfw/wrapper as glfw
import vector

import systems/windowing


type
  InputSystem* = ref object
    cursorPos*: vec2


var Input*: InputSystem


proc cursorMoved(i: InputSystem; x, y: float) =
  i.cursorPos = vec(x, y)


proc cursorCallback(win: GLFWwindow; x, y: cdouble) {.cdecl.} =
  Input.cursorMoved(x, y)


proc initInputSystem*() =
  Input = InputSystem()
  
  discard glfw.setCursorPosCallback(Window, cursorCallback)