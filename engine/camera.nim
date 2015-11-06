import logging
import strutils
import math

import config

import engine/vector
import engine/input
import engine/messaging
import engine/timekeeping
import engine/transform
import engine/renderer/screen
import engine/geometry/aabb


type
  CameraSystem* = ref object
    transform*: Transform

    projection*: mat4
    view*: mat4
    projectionView*: mat4
    projectionViewInverse*: mat4
    frustum*: array[8, vec3]
    boundingBox*: AABB

    listener: Listener
    zoom*: float
    panning: bool
    panCursorOrigin: vec2
    panOrigin: vec3


var Camera*: CameraSystem

proc projectNDC*(c: CameraSystem, p: vec3): vec3 = (c.projectionView * vec(p, 1.0)).xyz
proc unprojectNDC*(c: CameraSystem, p: vec3): vec3 = (c.projectionViewInverse * vec(p, 1.0)).xyz
proc project*(c: CameraSystem, p: vec3): vec3 = project(p, c.projectionView, Screen.viewport)
proc unproject*(c: CameraSystem, p: vec3): vec3 = unproject(p, c.projectionView, Screen.viewport)

proc getFrustum(c: CameraSystem): array[8, vec3] =
  result[0] = c.unprojectNDC(vec(-1, -1, -1))
  result[1] = c.unprojectNDC(vec( 1, -1, -1))
  result[2] = c.unprojectNDC(vec(-1,  1, -1))
  result[3] = c.unprojectNDC(vec( 1,  1, -1))

  result[4] = c.unprojectNDC(vec(-1, -1,  1))
  result[5] = c.unprojectNDC(vec( 1, -1,  1))
  result[6] = c.unprojectNDC(vec(-1,  1,  1))
  result[7] = c.unprojectNDC(vec( 1,  1,  1))

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
          Camera.transform.position = t - f * (shift + 8)
          Camera.zoom = z
        except ValueError:
          Messages.emit("Invalid zoom")

    else: discard

  if Camera.panning and Input.cursorPos != Camera.panCursorOrigin:
    Camera.transform.position = Camera.panOrigin - Camera.transform.forward
    let
      sΔ       = Input.cursorPos - Camera.panCursorOrigin
      sOrigin  = Camera.project(Camera.panOrigin)
      sTarget  = sOrigin - vec(sΔ, 0.0)
      wTarget  = Camera.unproject(sTarget)

      wΔ = wTarget - Camera.panOrigin

      f = Camera.transform.forward

      shift = f * (wΔ.y / f.y)
      shifted = wTarget - shift

    Camera.transform.position = shifted - Camera.transform.forward

  Camera.transform.updateMatrix()
  Camera.view = Camera.transform.getView()
  Camera.projectionView = Camera.projection * Camera.view
  Camera.projectionViewInverse = Camera.projectionView.inverse
  Camera.frustum = Camera.getFrustum()
  Camera.boundingBox = newAABB(Camera.frustum)

proc getViewRot*(c: CameraSystem): mat4 =
  result = c.view
  result[3] = 0.0
  result[7] = 0.0
  result[11] = 0.0
  result[12] = 0.0
  result[13] = 0.0
  result[14] = 0.0


proc pickGround*(c: CameraSystem, groundLevel: float32): vec3 =
  let
    near = c.unproject(vec(Input.cursorPos, 0.0))
    far  = c.unproject(vec(Input.cursorPos, 1.0))
    D    = far - near
    t    = (groundLevel - near.y) / D.y

  result = near + D * t


proc initCamera*() =
  Camera = CameraSystem(
    zoom: 15,
    projection: orthographic(-15 * Screen.aspectRatio, 15 * Screen.aspectRatio, -15, 15, 1, 50),
    #projection: perspective(50.0, windowWidth / windowHeight, 3, 50),
    transform: newTransform(p=vec(-15, 15, -8), f=vec(15, -15, 8)),
    listener: newListener()
  )
  Camera.listener.listen("camera")
  Time.schedule(updateCamera, hz=60)
