import logging
import vector
import config
import math
import systems/input
import systems/messaging

type
  CameraSystem* = ref object
    position*: vec3
    forward: vec3
    projection: mat4
    listener: Listener
    panning: bool
    panCursorOrigin: vec2
    panOrigin: vec3


var Camera*: CameraSystem


proc getProjection*(c: CameraSystem): mat4 = c.projection
proc getView*(c: CameraSystem): mat4 = lookAt(c.position, c.position + c.forward, yaxis)


proc initCamera*() =
  let ar = windowWidth / windowHeight
  Camera = CameraSystem(
    projection: orthographic(-15 * ar, 15 * ar, -15, 15, 1, 50),
    #projection: perspective(50.0, windowWidth / windowHeight, 3, 50),
    position: vec(-15, 15, -8),
    forward: vec(15, -15, 8),
    listener: newListener()
  )
  Camera.listener.listen("camera")

proc updateCamera*() =
  for e in Camera.listener.getMessages():
    case e:
    of "drag":
      Camera.panning = true
      Camera.panOrigin = Camera.position + Camera.forward
      Camera.panCursorOrigin = Input.cursorPos
    of "release":
      Camera.panning = false
    else: discard

  if Camera.panning:
    let
      viewport = vec(0.0, 0.0, windowWidth, windowHeight)
      sΔ       = Input.cursorPos - Camera.panCursorOrigin
      PV       = Camera.getProjection() * Camera.getView()
      sOrigin  = project(Camera.panOrigin, PV, viewport)
      sTarget  = vec(sOrigin.x - sΔ.x, sOrigin.y + sΔ.y, sOrigin.z)
      wTarget  = unproject(sTarget, PV, viewport)

      wΔ = wTarget - Camera.panOrigin
      f = Camera.forward.normalize()
      shift = wΔ.projectOn(yaxis).projectOn(f)
      shifted = wTarget - shift

    Camera.position = shifted - Camera.forward

proc getViewRot*(c: CameraSystem): mat4 =
  result = c.getView()
  result[3] = 0.0
  result[7] = 0.0
  result[11] = 0.0
  result[12] = 0.0
  result[13] = 0.0
  result[14] = 0.0
