import logging
import strutils
import vector
import config
import math
import systems/input
import systems/messaging
import systems/transform
import renderer/screen

type
  CameraSystem* = ref object
    transform*: Transform
    projection: mat4
    listener: Listener
    zoom*: float
    panning: bool
    panCursorOrigin: vec2
    panOrigin: vec3


var Camera*: CameraSystem


proc getProjection*(c: CameraSystem): mat4 = c.projection
proc getView*(c: CameraSystem): mat4 = c.transform.getView()


proc initCamera*() =
  Camera = CameraSystem(
    zoom: 15,
    projection: orthographic(-15 * Screen.aspectRatio, 15 * Screen.aspectRatio, -15, 15, 1, 50),
    #projection: perspective(50.0, windowWidth / windowHeight, 3, 50),
    transform: newTransform(p=vec(-15, 15, -8), f=vec(15, -15, 8)),
    listener: newListener()
  )
  Camera.listener.listen("camera")

proc updateCamera*() =
  for e in Camera.listener.getMessages():
    case e.name:
    of "drag":
      Camera.panning = true
      Camera.panOrigin = Camera.transform.position + Camera.transform.forward
      Camera.panCursorOrigin = Input.cursorPos

    of "release":
      Camera.panning = false

    of "zoom+":
      Messages.emit("camera.zoom", $(Camera.zoom + 1.0))

    of "zoom-":
      if Camera.zoom > 2.0:
        Messages.emit("camera.zoom", $(Camera.zoom - 1.0))

    of "zoom":
      if not Camera.panning:
        try:
          let
            z = parseFloat(e.payload)
            f = Camera.transform.forward
            p = Camera.transform.position
            t = p + f * ((-0.5 - p.y) / f.y)
            h = (Camera.transform.up * z).y
            shift = (h + 5.0) / Camera.transform.up.y
            far = 2 * shift + 5
          Camera.projection = orthographic(-Screen.aspectRatio * z, Screen.aspectRatio * z, -z, z, 1, far)
          Camera.transform.position = t - f * (shift + 1)
          Camera.zoom = z
        except ValueError:
          Messages.emit("Invalid zoom")

    else: discard

  if Camera.panning and Input.cursorPos != Camera.panCursorOrigin:
    Camera.transform.position = Camera.panOrigin - Camera.transform.forward
    let
      sΔ       = Input.cursorPos - Camera.panCursorOrigin
      PV       = Camera.getProjection() * Camera.getView()
      sOrigin  = project(Camera.panOrigin, PV, Screen.viewport)
      sTarget  = sOrigin - vec(sΔ, 0.0)
      wTarget  = unproject(sTarget, PV, Screen.viewport)

      wΔ = wTarget - Camera.panOrigin

      f = Camera.transform.forward

      shift = f * (wΔ.y / f.y)
      shifted = wTarget - shift

    Camera.transform.position = shifted - Camera.transform.forward

proc getViewRot*(c: CameraSystem): mat4 =
  result = c.getView()
  result[3] = 0.0
  result[7] = 0.0
  result[11] = 0.0
  result[12] = 0.0
  result[13] = 0.0
  result[14] = 0.0


proc pickGround*(c: CameraSystem, groundLevel: float32): vec3 =
  let
    p        = Input.cursorPos
    PV       = Camera.getProjection() * Camera.getView()
    near     = unproject(vec(p, 0.0), PV, Screen.viewport)
    far      = unproject(vec(p, 1.0), PV, Screen.viewport)
    D        = far - near
    t        = (groundLevel - near.y) / D.y

  result = near + D * t
