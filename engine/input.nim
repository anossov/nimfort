import unicode
import logging
import strutils
import strtabs
import glfw/wrapper as glfw

import config

import engine/vector
import engine/messaging
import engine/windowing


type
  InputSystem* = ref object
    cursorPos*: vec2
    listener: Listener
    binds: StringTableRef

  Device = enum
    Mouse
    Keyboard

  Button = object
    device: Device
    code: int
    scancode: int
    action: int
    mods: int

var Input*: InputSystem


proc cursorMoved(i: InputSystem; x, y: float) =
  i.cursorPos = vec(x, windowHeight - y)

proc charEvent(i: InputSystem, code: Rune) =
  Messages.emit("input.char",  code.int.toHex(8))

proc scrollEvent(i: InputSystem, x, y: float) =
  if y > 0:
    Messages.emit("input.SCROLL_UP")
  else:
    Messages.emit("input.SCROLL_DOWN")

proc buttonEvent(i: InputSystem; b: Button) =
  var parts = newSeq[string]()
  var k, a: string

  for i in 0..4:
    let bit = 1 shl i
    if (b.mods and bit) > 0:
      case bit:
        of MOD_SHIFT:   parts.add("shift")
        of MOD_CONTROL: parts.add("control")
        of MOD_ALT:     parts.add("alt")
        of MOD_SUPER:   parts.add("super")
        else:           parts.add("MOD" & $bit)

  case b.device:
  of Keyboard:
    case b.code:
    of KEY_SPACE:         k = "SPACE"
    of KEY_APOSTROPHE:    k = "APOSTROPHE"
    of KEY_COMMA:         k = "COMMA"
    of KEY_MINUS:         k = "MINUS"
    of KEY_PERIOD:        k = "PERIOD"
    of KEY_SLASH:         k = "SLASH"
    of KEY_0:             k = "0"
    of KEY_1:             k = "1"
    of KEY_2:             k = "2"
    of KEY_3:             k = "3"
    of KEY_4:             k = "4"
    of KEY_5:             k = "5"
    of KEY_6:             k = "6"
    of KEY_7:             k = "7"
    of KEY_8:             k = "8"
    of KEY_9:             k = "9"
    of KEY_SEMICOLON:     k = "SEMICOLON"
    of KEY_EQUAL:         k = "EQUAL"
    of KEY_A:             k = "A"
    of KEY_B:             k = "B"
    of KEY_C:             k = "C"
    of KEY_D:             k = "D"
    of KEY_E:             k = "E"
    of KEY_F:             k = "F"
    of KEY_G:             k = "G"
    of KEY_H:             k = "H"
    of KEY_I:             k = "I"
    of KEY_J:             k = "J"
    of KEY_K:             k = "K"
    of KEY_L:             k = "L"
    of KEY_M:             k = "M"
    of KEY_N:             k = "N"
    of KEY_O:             k = "O"
    of KEY_P:             k = "P"
    of KEY_Q:             k = "Q"
    of KEY_R:             k = "R"
    of KEY_S:             k = "S"
    of KEY_T:             k = "T"
    of KEY_U:             k = "U"
    of KEY_V:             k = "V"
    of KEY_W:             k = "W"
    of KEY_X:             k = "X"
    of KEY_Y:             k = "Y"
    of KEY_Z:             k = "Z"
    of KEY_LEFT_BRACKET:  k = "LEFT_BRACKET"
    of KEY_BACKSLASH:     k = "BACKSLASH"
    of KEY_RIGHT_BRACKET: k = "RIGHT_BRACKET"
    of KEY_GRAVE_ACCENT:  k = "GRAVE_ACCENT"
    of KEY_WORLD_1:       k = "WORLD_1"
    of KEY_WORLD_2:       k = "WORLD_2"
    of KEY_ESCAPE:        k = "ESCAPE"
    of KEY_ENTER:         k = "ENTER"
    of KEY_TAB:           k = "TAB"
    of KEY_BACKSPACE:     k = "BACKSPACE"
    of KEY_INSERT:        k = "INSERT"
    of KEY_DELETE:        k = "DELETE"
    of KEY_RIGHT:         k = "RIGHT"
    of KEY_LEFT:          k = "LEFT"
    of KEY_DOWN:          k = "DOWN"
    of KEY_UP:            k = "UP"
    of KEY_PAGE_UP:       k = "PAGE_UP"
    of KEY_PAGE_DOWN:     k = "PAGE_DOWN"
    of KEY_HOME:          k = "HOME"
    of KEY_END:           k = "END"
    of KEY_CAPS_LOCK:     k = "CAPS_LOCK"
    of KEY_SCROLL_LOCK:   k = "SCROLL_LOCK"
    of KEY_NUM_LOCK:      k = "NUM_LOCK"
    of KEY_PRINT_SCREEN:  k = "PRINT_SCREEN"
    of KEY_PAUSE:         k = "PAUSE"
    of KEY_F1:            k = "F1"
    of KEY_F2:            k = "F2"
    of KEY_F3:            k = "F3"
    of KEY_F4:            k = "F4"
    of KEY_F5:            k = "F5"
    of KEY_F6:            k = "F6"
    of KEY_F7:            k = "F7"
    of KEY_F8:            k = "F8"
    of KEY_F9:            k = "F9"
    of KEY_F10:           k = "F10"
    of KEY_F11:           k = "F11"
    of KEY_F12:           k = "F12"
    of KEY_F13:           k = "F13"
    of KEY_F14:           k = "F14"
    of KEY_F15:           k = "F15"
    of KEY_F16:           k = "F16"
    of KEY_F17:           k = "F17"
    of KEY_F18:           k = "F18"
    of KEY_F19:           k = "F19"
    of KEY_F20:           k = "F20"
    of KEY_F21:           k = "F21"
    of KEY_F22:           k = "F22"
    of KEY_F23:           k = "F23"
    of KEY_F24:           k = "F24"
    of KEY_F25:           k = "F25"
    of KEY_KP_0:          k = "KP_0"
    of KEY_KP_1:          k = "KP_1"
    of KEY_KP_2:          k = "KP_2"
    of KEY_KP_3:          k = "KP_3"
    of KEY_KP_4:          k = "KP_4"
    of KEY_KP_5:          k = "KP_5"
    of KEY_KP_6:          k = "KP_6"
    of KEY_KP_7:          k = "KP_7"
    of KEY_KP_8:          k = "KP_8"
    of KEY_KP_9:          k = "KP_9"
    of KEY_KP_DECIMAL:    k = "KP_DECIMAL"
    of KEY_KP_DIVIDE:     k = "KP_DIVIDE"
    of KEY_KP_MULTIPLY:   k = "KP_MULTIPLY"
    of KEY_KP_SUBTRACT:   k = "KP_SUBTRACT"
    of KEY_KP_ADD:        k = "KP_ADD"
    of KEY_KP_ENTER:      k = "KP_ENTER"
    of KEY_KP_EQUAL:      k = "KP_EQUAL"
    of KEY_LEFT_SHIFT:    k = "LEFT_SHIFT"
    of KEY_LEFT_CONTROL:  k = "LEFT_CONTROL"
    of KEY_LEFT_ALT:      k = "LEFT_ALT"
    of KEY_LEFT_SUPER:    k = "LEFT_SUPER"
    of KEY_RIGHT_SHIFT:   k = "RIGHT_SHIFT"
    of KEY_RIGHT_CONTROL: k = "RIGHT_CONTROL"
    of KEY_RIGHT_ALT:     k = "RIGHT_ALT"
    of KEY_RIGHT_SUPER:   k = "RIGHT_SUPER"
    of KEY_MENU:          k = "MENU"
    of KEY_UNKNOWN:       return
    else:                 return
  of Mouse:
    case b.code:
    of MOUSE_BUTTON_1: k = "LMB"
    of MOUSE_BUTTON_2: k = "RMB"
    of MOUSE_BUTTON_3: k = "MMB"
    of MOUSE_BUTTON_4: k = "MB_4"
    of MOUSE_BUTTON_5: k = "MB_5"
    of MOUSE_BUTTON_6: k = "MB_6"
    of MOUSE_BUTTON_7: k = "MB_7"
    of MOUSE_BUTTON_8: k = "MB_8"
    else: return
  parts.add(k)

  case b.action:
  of PRESS:   a = "down"
  of RELEASE: a = "up"
  of REPEAT:  a = "repeat"
  else:       return
  parts.add(a)

  Messages.emit("input." & parts.join(sep="-"))

proc cursorCallback(win: GLFWwindow; x, y: cdouble) {.cdecl.} =
  Input.cursorMoved(x, y)

proc keyCallback(win: GLFWwindow; key, scancode, action, mods: cint) {.cdecl.} =
  Input.buttonEvent(Button(device: Keyboard, code: key, scancode: scancode, action: action, mods: mods))

proc charCallback(win: GLFWwindow; codepoint: cuint) {.cdecl.} =
  Input.charEvent(codepoint.Rune)

proc mbCallback(win: GLFWwindow; button, action, mods: cint) {.cdecl.} =
  Input.buttonEvent(Button(device: Mouse, code: button, action: action, mods: mods))

proc scrollCallback(win: GLFWwindow; xoffset, yoffset: cdouble) {.cdecl.} =
  Input.scrollEvent(xoffset, yoffset)

proc mapInput*(input: string, event: string) =
  Input.binds[input] = event

proc initInputSystem*() =
  Input = InputSystem(
    listener: newListener(),
    binds: newStringTable(modeCaseSensitive),
  )

  Input.listener.listen("input")

  discard glfw.setCursorPosCallback(Window, cursorCallback)
  discard glfw.setKeyCallback(Window, keyCallback)
  discard glfw.setCharCallback(Window, charCallback)
  discard glfw.setMouseButtonCallback(Window, mbCallback)
  discard glfw.setScrollCallback(Window, scrollCallback)

  for b, e in items(bindings):
    mapInput(b, e)

  info("Input ok")

proc updateInput*() =
  for m in Input.listener.getMessages():
    if Input.binds.hasKey(m.name):
      Messages.emit(Input.binds[m.name])


proc hideCursor*(i: InputSystem) =
  glfw.setInputMode(Window, CURSOR, CURSOR_HIDDEN)


proc disableCursor*(i: InputSystem) =
  glfw.setInputMode(Window, CURSOR, CURSOR_DISABLED)


proc showCursor*(i: InputSystem) =
  glfw.setInputMode(Window, CURSOR, CURSOR_NORMAL)
