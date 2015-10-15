import logging
import strutils
import text
import objfile
import mesh
import nimPNG

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

proc getModel*(r: ResourceManager, name: string): Mesh = 
  let
    data = loadObj("assets/models/$1.obj" % name)
    image = loadPNG32("assets/textures/$1.png" % name)

  var texture = newTexture()
  texture.image2d(image.data, image.width.int32, image.height.int32)
  texture.filter(true)

  newMesh(data, texture)