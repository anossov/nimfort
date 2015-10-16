import logging
import strutils
import text
import objfile
import mesh
import nimPNG
import opengl

import gl/texture
import gl/shader


type
  ResourceManager = ref object
    discard

var Resources*: ResourceManager


proc initResources*() = 
  Resources = ResourceManager()


proc getFont*(r: ResourceManager, name: string): Font = 
  loadFont("assets/fonts/$1.fnt" % name)

proc getShader*(r: ResourceManager, name: string): Program = 
  createProgram(
    readFile("assets/shaders/$1.vs.glsl" % name),
    readFile("assets/shaders/$1.fs.glsl" % name),
  )

proc getTexture*(r: ResourceManager, name: string, srgb=true): Texture =
  let image = loadPNG32("assets/textures/$1.png" % name)
  let f = if srgb: GL_SRGB else: GL_RGBA
  result = newTexture()
  result.image2d(image.data, image.width.int32, image.height.int32, internalformat=f)
  result.filter(true)

proc getModel*(r: ResourceManager, name: string, t=true): Mesh = 
  let
    data = loadObj("assets/models/$1.obj" % name)

  var texture: Texture
  if t:
    texture = r.getTexture(name)
  else:
    texture = newTexture()

  newMesh(data, texture)