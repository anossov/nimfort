import systems/ecs
import vector
import mesh


type
  Transform* = object
    rotation*: vec3
    position: vec3
    scale: vec3
    matrix: mat4

  Renderable3d* = object of Component
    transform*: Transform
    mesh*: Mesh

  Renderable2d* = object of Component
    transform*: Transform
    mesh*: Mesh

  Light* = object of Component
    position*: vec3
    target*: vec3
    directional*: bool
    shadows*: bool


proc updateMatrix*(t: var Transform) = 
  let rot = rotate(xaxis, t.rotation.x) * rotate(yaxis, t.rotation.y) * rotate(zaxis, t.rotation.z)
  t.matrix = translate(t.position) * rot * scale(t.scale)


proc newTransform*(p: vec3, r=zeroes3, s=ones3): Transform = 
  result.position = p
  result.rotation = r
  result.scale = s
  result.updateMatrix()