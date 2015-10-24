import logging
import systems/ecs
import vector
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
    Ambient
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

  GhettoIBL* = object of Component
    cubemap*: Texture

  Label* = object of Component
    color*: vec3
    mesh*: Mesh
    texture*: Texture

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

proc newAmbientLight*(color=ones3): Light =
  Light(
    kind: Ambient,
    color: color,
    shadowMap: emptyTexture(),
  )

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

proc newSkybox*(t: Texture): Skybox =
  Skybox(cubemap: t)

proc newGhettoIBL*(t: Texture): GhettoIBL =
  GhettoIBL(cubemap: t)

proc getProjection*(light: Light): mat4 =
  if light.kind == Directional:
    return orthographic(-20.0, 20.0, -20.0, 20.0, 2, 50.0)
  if light.kind == Spot:
    return perspective(light.spotFalloff * 2, 1.0, 1, 80.0)
  return identity()


ImplementComponent(Light, light)
ImplementComponent(Model, model)
ImplementComponent(Label, label)
ImplementComponent(Skybox, skybox)
ImplementComponent(GhettoIBL, ibl)
