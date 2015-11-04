import logging
import math
import opengl

import config

import gl/texture

import engine/ecs
import engine/vector
import engine/text
import engine/mesh
import engine/camera
import engine/resources
import engine/transform
import engine/geometry/aabb


type
  Model* = object of Component
    mesh*: Mesh
    textures*: seq[Texture]
    shadows*: bool
    emissionIntensity*: float
    emissionOnly*: bool
    bb*: AABB

  Overlay* = object of Component
    mesh*: Mesh
    color*: vec4

  LightType* = enum
    Point
    Directional
    Spot

  Light* = object of Component
    kind*: LightType
    color*: vec3
    shadows*: bool
    radius*: float32
    spotAngle*: float32
    spotFalloff*: float32
    shadowMap*: Texture

  Skybox* = object of Component
    cubemap*: Texture
    intensity*: vec3

  AmbientCube* = object of Component
    colors*: array[6, vec3]

  GhettoIBL* = object of Component
    cubemap*: Texture
    color*: vec3

  LabelAlign* = enum
    AlignLeft
    AlignRight

  Label* = object of Component
    text*: string
    color*: vec4
    mesh*: TextMesh
    align*: LabelAlign
    texture*: Texture
    fade*: bool
    fadeTime*: float

proc newModel*(m: Mesh,
               albedo: Texture,
               normal=emptyTexture(),
               roughness=emptyTexture(),
               metalness=emptyTexture(),
               emission=emptyTexture(),
               emissionIntensity=0.0,
               shadows=true,
               emissionOnly=false): Model =
  result = Model(
    mesh: m,
    textures: newSeq[Texture](5),
    bb: newAABB()
  )
  result.textures[0] = albedo
  result.textures[1] = normal
  result.textures[2] = roughness
  result.textures[3] = metalness
  result.textures[4] = emission
  result.shadows = shadows
  result.emissionIntensity = emissionIntensity
  result.emissionOnly = emissionOnly
  for v in m.vertices:
    result.bb.add(v.position)

proc newAmbientCube*(posx=ones3, negx=ones3, posy=ones3, negy=ones3, posz=ones3, negz=ones3): AmbientCube =
  AmbientCube(
    colors: [posx, negx, posy, negy, posz, negz]
  )

proc newAmbientLight*(color=ones3): AmbientCube =
  newAmbientCube(color, color, color, color, color, color)

proc newPointLight*(color=ones3, radius=1.0, shadows=false): Light =
  Light(
    kind: Point,
    radius: radius,
    color: color,
    shadows: shadows,
    shadowMap: emptyTexture(),
  )

proc newDirLight*(color=ones3, shadows=false): Light =
  Light(
    kind: Directional,
    shadows: shadows,
    color: color,
    shadowMap: emptyTexture(),
  )

proc newSpotLight*(color=ones3, angle=30.0, falloff=60.0, shadows=false): Light =
  Light(
    kind: Spot,
    shadows: shadows,
    spotAngle: angle,
    spotFalloff: falloff,
    color: color,
    shadowMap: emptyTexture(),
  )

proc newSkybox*(t: Texture, intensity=ones3): Skybox =
  Skybox(cubemap: t, intensity: intensity)

proc newGhettoIBL*(t: Texture, c: vec3): GhettoIBL =
  GhettoIBL(cubemap: t, color: c)

proc getFaceSpace*(light: Light, face: int): mat4 =
  var f, u: vec3
  case face:
    of GL_TEXTURE_CUBE_MAP_POSITIVE_X:
      f = vec(1, 0, 0)
      u = vec(0, -1, 0)
    of GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
      f = vec(-1, 0, 0)
      u = vec(0, -1, 0)
    of GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
      f = vec(0, 1, 0)
      u = vec(0, 0, 1)
    of GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
      f = vec(0, -1, 0)
      u = vec(0, 0, -1)
    of GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
      f = vec(0, 0, 1)
      u = vec(0, -1, 0)
    of GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
      f = vec(0, 0, -1)
      u = vec(0, -1, 0)
    else: discard

  let p = light.entity.transform.position
  let view = lookAt(p, p + f, u)
  let proj = perspective(90.0, 1.0, 0.1, light.radius)

  return proj * view


proc getSpace*(light: Light): mat4 =
  case light.kind:
  of Directional:
    let
      frustumCenter = Camera.unprojectNDC(vec(0, 0, 0))
      frustum = Camera.frustum

    let frustumDiag = distance(frustum[0], frustum[7])

    light.entity.transform.position = frustumCenter - light.entity.transform.forward * frustumDiag
    light.entity.transform.updateMatrix()

    let
      lv = light.entity.transform.matrix
      ilv = lv.inverse
      v = light.entity.transform.getView()

    var bb = newAABB()
    for corner in frustum:
      let p = ilv * vec(corner, 1.0)
      bb.add(p.xyz)

    let p = orthographic(bb.min.x, bb.max.x, bb.min.y, bb.max.y, -bb.max.z, -bb.min.z)
    return p * light.entity.transform.getView()
  of Spot:
    let p = perspective(light.spotFalloff * 2, 1.0, 1, 80.0)
    return p * light.entity.transform.getView()
  of Point:
    return translate(-light.entity.transform.position)
  else:
    return identity()

proc frustum*(light: Light): array[8, vec3] =
  let m = light.getSpace().inverse
  result[0] = (m * vec(-1, -1, -1, 1.0)).xyz
  result[1] = (m * vec( 1, -1, -1, 1.0)).xyz
  result[2] = (m * vec(-1,  1, -1, 1.0)).xyz
  result[3] = (m * vec( 1,  1, -1, 1.0)).xyz
  result[4] = (m * vec(-1, -1,  1, 1.0)).xyz
  result[5] = (m * vec( 1, -1,  1, 1.0)).xyz
  result[6] = (m * vec(-1,  1,  1, 1.0)).xyz
  result[7] = (m * vec( 1,  1,  1, 1.0)).xyz


proc boundingBox*(light: Light): AABB =
  case light.kind:
  of Point:
    let p = light.entity.transform.position
    return newAABB(vec(p - light.radius, 1.0), vec(p + light.radius, 1.0))
  else:
    return newAABB(light.frustum)


proc update*(t: var Label, s: string) =
  if t.text != s:
    let xpos = t.entity.transform.position.x + t.mesh.width * t.entity.transform.scale.x
    t.text = s
    t.mesh.update(s)
    if t.align == AlignRight:
      t.entity.transform.position.x = xpos - t.mesh.width * t.entity.transform.scale.x
      t.entity.transform.updateMatrix()

ImplementComponent(Light, light)
ImplementComponent(AmbientCube, ambientCube)
ImplementComponent(Model, model)
ImplementComponent(Label, label)
ImplementComponent(Skybox, skybox)
ImplementComponent(GhettoIBL, ibl)
ImplementComponent(Overlay, overlay)

