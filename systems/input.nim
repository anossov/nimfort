import logging
import messaging
import glfw/wrapper as glfw
import glfw as glfwHigh
import vector

import systems/windowing


type
  InputSystem* = ref object
    cursorPos*: vec2


var Input*: InputSystem


proc cursorMoved(i: InputSystem; x, y: float) =
  i.cursorPos = vec(x, y)


proc keyEvent(i: InputSystem; key: Key, scancode: int, action: KeyAction, mods: int) =
  case key:
  of keyW:
    case action:
    of kaDown:
      Messages.emit("wire-on")
    of kaUp:
      Messages.emit("wire-off")
    of kaRepeat:
      discard
  of keyQ:
    if action == kaDown:
      Messages.emit("quit")
  else:
    discard

proc cursorCallback(win: GLFWwindow; x, y: cdouble) {.cdecl.} =
  Input.cursorMoved(x, y)

proc keyCallback(win: GLFWwindow; key, scancode, action, mods: cint) {.cdecl.} =
  Input.keyEvent(key.Key, scancode, action.KeyAction, mods)

proc initInputSystem*() =
  Input = InputSystem()

  discard glfw.setCursorPosCallback(Window, cursorCallback)
  discard glfw.setKeyCallback(Window, keyCallback)

  info("Input ok")
