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

proc flipimage(data: string; w, h: int): string = 
  result = ""
  let stride = w * 4
  for i in 0..h:
    let
      f = (h-i) - 1
      t = (h-i)
    result.add(data[f * stride..t * stride - 1])

proc getTexture*(r: ResourceManager, name: string, srgb=true): Texture =
  let image = loadPNG32("assets/textures/$1.png" % name)
  let f = if srgb: GL_SRGB else: GL_RGBA
  let data = flipimage(image.data, image.width, image.height)
  
  result = newTexture()
  result.image2d(data, image.width.int32, image.height.int32, internalformat=f)
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