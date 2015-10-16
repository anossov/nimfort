import systems/ecs
import vector
import mesh
import gl/texture


type
  Transform* = object
    rotation*: vec3
    position*: vec3
    scale*: vec3
    matrix*: mat4

  Renderable3d* = object of Component
    transform*: Transform
    mesh*: Mesh

  LightType* = enum
    Directional
    Point
    Spot

  Light* = object of Component
    position*: vec3
    target*: vec3
    kind*: LightType
    attenuation*: vec3
    shadows*: bool
    shadowMap*: Texture

  Label* = object of Component
    transform*: Transform
    mesh*: Mesh


proc updateMatrix*(t: var Transform) = 
  let rot = rotate(xaxis, t.rotation.x) * rotate(yaxis, t.rotation.y) * rotate(zaxis, t.rotation.z)
  t.matrix = translate(t.position) * rot * scale(t.scale)


proc newTransform*(p: vec3, r=zeroes3, s=ones3): Transform = 
  result.position = p
  result.rotation = r
  result.scale = s
  result.updateMatrix()


proc newLight*(kind: LightType, position=zeroes3, target=zeroes3, shadows=false, attenuation=xaxis): Light = 
  Light(
    position: position,
    target: target,
    kind: kind,
    shadows: shadows,
    attenuation: attenuation,
    shadowMap: emptyTexture(),
  )

proc getView*(light: Light): mat4 = lookAt(light.position, light.target, yaxis)

proc getProjection*(light: Light): mat4 = orthographic(-2.0, 2.0, -2.0, 2.0, 2, 10.0)