import logging
import strutils
import text
import objfile
import mesh
import nimBMP
import opengl
import tables
import vector

import gl/texture
import gl/shader

type
  ResourceManager = ref object
    textures: Table[string, Texture]
    shaders: Table[string, Program]
    meshes: Table[string, Mesh]

var Resources*: ResourceManager


proc initResources*() =
  Resources = ResourceManager(
    textures: initTable[string, Texture](),
    shaders: initTable[string, Program](),
    meshes: initTable[string, Mesh](),
  )


proc getFont*(name: string): Font =
  loadFont("assets/fonts/$1.fnt" % name)


proc getShader*(name: string, vs_prepend: openarray[string] = [], fs_prepend: openarray[string] = []): Program =
  if not Resources.shaders.hasKey(name):
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

    Resources.shaders[name] = createProgram(vss, fss)

  return Resources.shaders[name]


proc flipimage*(data: string; w, h: int): string =
  result = ""
  let stride = w * 4
  for i in 0..h:
    let
      f = (h-i) - 1
      t = (h-i)
    result.add(data[f * stride..t * stride - 1])


proc getTexture*(name: string, srgb=false): Texture =
  if not Resources.textures.hasKey(name):
    let image = loadBMP32("assets/textures/$1.bmp" % name)
    let f = if srgb: GL_SRGB else: GL_RGBA
    let data = flipimage(image.data, image.width, image.height)

    var t = newTexture()
    t.image2d(f.int32, image.width.int32, image.height.int32, TextureFormat.RGBA, PixelType.Ubyte, data=data)
    t.generateMipmap()
    t.filter(true)
    Resources.textures[name] = t
  return Resources.textures[name]


proc getColorTexture*(color: vec4): Texture =
  let c = color * 255
  let colorName = c.x.int.toHex(2) & c.y.int.toHex(2) & c.z.int.toHex(2) & c.w.int.toHex(2)
  if not Resources.textures.hasKey(colorName):
    var t = newTexture()
    let data = c.x.int.chr & c.y.int.chr & c.z.int.chr & c.w.int.chr
    t.image2d(GL_RGBA, 1, 1, TextureFormat.RGBA, PixelType.Ubyte, data=data)
    t.clamp()
    t.filter(false)
    Resources.textures[colorName] = t

  return Resources.textures[colorName]


proc getMesh*(name: string, t=true): Mesh =
  if not Resources.meshes.hasKey(name):
    Resources.meshes[name] = loadObj("assets/models/$1.obj" % name)

  return Resources.meshes[name]
