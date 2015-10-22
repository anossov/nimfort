import logging
import strutils
import text
import objfile
import mesh
import nimBMP
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

proc getShader*(r: ResourceManager, name: string, vs_prepend: openarray[string] = [], fs_prepend: openarray[string] = []): Program =
  let
    vs = readFile("assets/shaders/$1.vs.glsl" % name)
    fs = readFile("assets/shaders/$1.fs.glsl" % name)
  var fss = ""
  var vss = ""
  for n in fs_prepend:
    fss.add(readFile("assets/shaders/$1.inc.glsl" % n))
  for n in vs_prepend:
    vss.add(readFile("assets/shaders/$1.inc.glsl" % n))
  fss.add(fs)
  vss.add(vs)

  createProgram(vss, fss)

proc flipimage*(data: string; w, h: int): string =
  result = ""
  let stride = w * 4
  for i in 0..h:
    let
      f = (h-i) - 1
      t = (h-i)
    result.add(data[f * stride..t * stride - 1])

proc getTexture*(r: ResourceManager, name: string, srgb=false): Texture =
  let image = loadBMP32("assets/textures/$1.bmp" % name)
  let f = if srgb: GL_SRGB else: GL_RGBA
  let data = flipimage(image.data, image.width, image.height)

  result = newTexture()
  result.image2d(f.int32, image.width.int32, image.height.int32, TextureFormat.RGBA, PixelType.Ubyte, data=data)
  result.generateMipmap()
  result.filter(true)


proc getMesh*(r: ResourceManager, name: string, t=true): Mesh =
  result = loadObj("assets/models/$1.obj" % name)
