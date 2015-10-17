import systems/ecs
import vector
import mesh
import math
import gl/texture
import systems/camera
import config

type
  Transform* = object
    rotation*: vec3
    position*: vec3
    scale*: vec3
    matrix*: mat4

  Model* = object of Component
    transform*: Transform
    mesh*: Mesh
    textures*: array[3, Texture]
    shadows*: bool

  LightType* = enum
    Directional
    Point
    Spot

  Light* = object of Component
    position*: vec3
    target*: vec3
    kind*: LightType
    radius*: float32
    shadows*: bool
    shadowMap*: Texture

  Label* = object of Component
    transform*: Transform
    color*: vec3
    mesh*: Mesh
    texture*: Texture


proc updateMatrix*(t: var Transform) = 
  let rot = rotate(xaxis, t.rotation.x) * rotate(yaxis, t.rotation.y) * rotate(zaxis, t.rotation.z)
  t.matrix = translate(t.position) * rot * scale(t.scale)


proc newTransform*(p=zeroes3, r=zeroes3, s=ones3): Transform = 
  result.position = p
  result.rotation = r
  result.scale = s
  result.updateMatrix()

proc newTransform*(p=zeroes3, r=zeroes3, s: float32): Transform {.inline.} = newTransform(p, r, vec(s, s, s))


proc newModel*(t: Transform, m: Mesh, diffuse: Texture, normal=emptyTexture(), specular=emptyTexture(), shadows=true): Model =
  Model(
    transform: t,
    mesh: m,
    textures: [diffuse, normal, specular],
    shadows: shadows
  )

proc newLight*(kind: LightType, position=zeroes3, target=zeroes3, shadows=false, radius=1.0): Light = 
  Light(
    position: position,
    target: target,
    kind: kind,
    shadows: shadows,
    radius: radius,
    shadowMap: emptyTexture(),
  )

proc getView*(light: Light): mat4 = lookAt(light.position, light.target, yaxis)

proc getProjection*(light: Light): mat4 = orthographic(-2.0, 2.0, -2.0, 2.0, 2, 10.0)

proc getScreenExtentsTransform*(light: Light): mat4 = 
  if light.kind != Point:
    return identity()

  let
    v = Camera.getView()
    viewProjection = Camera.getProjection() * v
    bb = mat4([
      v[0], v[4], v[8], 0.0,
      v[1], v[5], v[9], 0.0,
      v[2], v[6], v[10], 0.0,
      0.0, 0.0, 0.0, 1.0,
    ])
    
  return viewProjection * translate(light.position) * bb * scale(light.radius)