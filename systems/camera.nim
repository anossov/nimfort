import logging
import strutils
import vector
import config
import math
import systems/input
import systems/messaging

type
  CameraSystem* = ref object
    position*: vec3
    forward*: vec3
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
    case e.name:
    of "drag":
      Camera.panning = true
      Camera.panOrigin = Camera.position + Camera.forward
      Camera.panCursorOrigin = Input.cursorPos

    of "release":
      Camera.panning = false

    of "pick":
      let
        viewport = vec(0.0, 0.0, windowWidth, windowHeight)
        p        = Input.cursorPos
        PV       = Camera.getProjection() * Camera.getView()
        near     = unproject(vec(p.x, windowHeight-p.y, 0.0), PV, viewport)
        far      = unproject(vec(p.x, windowHeight-p.y, 1.0), PV, viewport)
        D        = far - near
        t        = (-0.5 - near.dot(yaxis)) / D.dot(yaxis)
        pick     = near + D * t
      Messages.emit("info", $pick)

    else: discard

  if Camera.panning and Input.cursorPos != Camera.panCursorOrigin:
    Camera.position = Camera.panOrigin - Camera.forward
    let
      viewport = vec(0.0, 0.0, windowWidth, windowHeight)
      sΔ       = Input.cursorPos - Camera.panCursorOrigin
      PV       = Camera.getProjection() * Camera.getView()
      sOrigin  = project(Camera.panOrigin, PV, viewport)
      sTarget  = vec(sOrigin.x - sΔ.x, sOrigin.y + sΔ.y, sOrigin.z)
      wTarget  = unproject(sTarget, PV, viewport)

      wΔ = wTarget - Camera.panOrigin

      f = Camera.forward.normalize()

      shift = f * (-wΔ.y / (yaxis.dot(-f)))
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
