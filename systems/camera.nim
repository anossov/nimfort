import vector
import config
import math
import systems/input

type
  CameraSystem* = ref object
    position*: vec3
    target: vec3

    projection: mat4


var Camera*: CameraSystem


proc initCamera*() =
  Camera = CameraSystem(
    projection: perspective(45.0, windowWidth / windowHeight, 3, 200.0),
  )

proc updateCamera*() =
  var
    phi = (windowWidth - Input.cursorPos.x) / 200
    theta = (windowHeight - Input.cursorPos.y) / 200

  if theta < PI * 0.51:
    theta = PI * 0.51
  if theta > PI * 1.49:
    theta = PI * 1.49

  Camera.position.x = sin(phi) * cos(theta) * 25
  Camera.position.y = sin(theta) * 25
  Camera.position.z = cos(phi) * cos(theta) * 25


proc getView*(c: CameraSystem): mat4 = lookAt(c.position, c.target, yaxis)

proc getViewRot*(c: CameraSystem): mat4 =
  result = c.getView()
  result[3] = 0.0
  result[7] = 0.0
  result[11] = 0.0
  result[12] = 0.0
  result[13] = 0.0
  result[14] = 0.0

proc getProjection*(c: CameraSystem): mat4 = c.projection
