import logging
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
    Ambient
    Point
    Directional
    Spot

  Light* = object of Component
    kind*: LightType
    position*: vec3
    target*: vec3
    color*: vec3
    shadows*: bool
    radius*: float32
    spotAngle*: float32
    spotFalloff*: float32
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

proc newAmbientLight*(color=ones3): Light = 
  Light(
    kind: Ambient,
    color: color,
    shadowMap: emptyTexture(),
  )

proc newPointLight*(position=zeroes3, color=ones3, radius=1.0): Light = 
  Light(
    position: position,
    kind: Point,
    radius: radius,
    color: color,
    shadowMap: emptyTexture(),
  )

proc newDirLight*(position=zeroes3, color=ones3, target=zeroes3, shadows=false): Light = 
  Light(
    position: position,
    target: target,
    kind: Directional,
    shadows: shadows,
    color: color,
    shadowMap: emptyTexture(),
  )

proc newSpotLight*(position=zeroes3, color=ones3, target=zeroes3, angle=30.0, falloff=60.0, shadows=false): Light = 
  Light(
    position: position,
    target: target,
    kind: Spot,
    shadows: shadows,
    spotAngle: angle,
    spotFalloff: falloff,
    color: color,
    shadowMap: emptyTexture(),
  )

proc getView*(light: Light): mat4 =
  let a = yaxis.angle(light.target-light.position)

  if a < 0.001 or a > 2*PI - 0.001:
    return lookAt(light.position, light.target, xaxis)
  else:
    return lookAt(light.position, light.target, yaxis)
  
proc getProjection*(light: Light): mat4 =
  if light.kind == Directional:
    return orthographic(-20.0, 20.0, -20.0, 20.0, 2, 50.0)
  if light.kind == Spot:
    return perspective(light.spotFalloff * 2, 1.0, 1, 80.0)
  return identity()