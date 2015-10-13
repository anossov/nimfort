import logging
import messaging
import glfw/wrapper as glfw
import vector

type
  InputSystem* = ref object
    messages: MessageSystem
    window: GLFWwindow

    cursorPos*: vec2

var globalInput: InputSystem


proc cursorMoved(i: InputSystem; x, y: float) =
  i.cursorPos = vec(x, y)


proc cursorCallback(win: GLFWwindow; x, y: cdouble) {.cdecl.} =
  globalInput.cursorMoved(x, y)


proc newInputSystem*(m: MessageSystem, win: GLFWwindow): InputSystem =
  result = InputSystem(
    messages: m,
    window: win,
  )
  
  globalInput = result
  discard glfw.setCursorPosCallback(win, cursorCallback)