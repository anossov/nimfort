import logging
import systems/ecs
import vector
import text
import mesh
import math
import gl/texture
import systems/camera
import systems/resources
import config

type
  Model* = object of Component
    mesh*: Mesh
    textures*: seq[Texture]
    shadows*: bool
    emissionIntensity*: float

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

  Label* = object of Component
    text*: string
    color*: vec4
    mesh*: TextMesh
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
               shadows=true): Model =
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

proc getProjection*(light: Light): mat4 =
  if light.kind == Directional:
    return orthographic(-60.0, 60.0, -60.0, 60.0, 2, 150.0)
  if light.kind == Spot:
    return perspective(light.spotFalloff * 2, 1.0, 1, 80.0)
  return identity()


proc update*(t: var Label, s: string) =
  if t.text != s:
    t.text = s
    t.mesh.update(s)


ImplementComponent(Light, light)
ImplementComponent(AmbientCube, ambientCube)
ImplementComponent(Model, model)
ImplementComponent(Label, label)
ImplementComponent(Skybox, skybox)
ImplementComponent(GhettoIBL, ibl)
