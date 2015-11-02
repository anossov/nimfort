import logging
import math

import config

import gl/texture

import engine/ecs
import engine/vector
import engine/text
import engine/mesh
import engine/camera
import engine/resources
import engine/transform


type
  Model* = object of Component
    mesh*: Mesh
    textures*: seq[Texture]
    shadows*: bool
    emissionIntensity*: float
    emissionOnly*: bool

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
  )
  result.textures[0] = albedo
  result.textures[1] = normal
  result.textures[2] = roughness
  result.textures[3] = metalness
  result.textures[4] = emission
  result.shadows = shadows
  result.emissionIntensity = emissionIntensity
  result.emissionOnly = emissionOnly

proc newAmbientCube*(posx=ones3, negx=ones3, posy=ones3, negy=ones3, posz=ones3, negz=ones3): AmbientCube =
  AmbientCube(
    colors: [posx, negx, posy, negy, posz, negz]
  )

proc newAmbientLight*(color=ones3): AmbientCube =
  newAmbientCube(color, color, color, color, color, color)

proc newPointLight*(color=ones3, radius=1.0): Light =
  Light(
    kind: Point,
    radius: radius,
    color: color,
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

    var fbb: array[2, vec3]
    fbb[0] = vec(Inf, Inf, Inf)
    fbb[1] = vec(-Inf, -Inf, -Inf)
    for corner in frustum:
      let p = ilv * vec(corner, 1.0)
      if p.x <= fbb[0].x:
        fbb[0].x = p.x
      if p.y <= fbb[0].y:
        fbb[0].y = p.y
      if p.z <= fbb[0].z:
        fbb[0].z = p.z

      if p.x >= fbb[1].x:
        fbb[1].x = p.x
      if p.y >= fbb[1].y:
        fbb[1].y = p.y
      if p.z >= fbb[1].z:
        fbb[1].z = p.z

    let p = orthographic(fbb[0].x, fbb[1].x, fbb[0].y, fbb[1].y, -fbb[1].z, -fbb[0].z)
    return p * light.entity.transform.getView()
  of Spot:
    let p = perspective(light.spotFalloff * 2, 1.0, 1, 80.0)
    return p * light.entity.transform.getView()
  else:
    return identity()


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
