import os
import logging
import tables
import hashes
import strutils
import unicode
import gl/texture
import gl/buffer
import gl/shader
import opengl
import vector
import mesh
import nimPNG

type
  Char = object
    id: Rune
    pos: vec2
    size: vec2
    offset: vec2
    advance: float32

  Font* = ref object
    textures*: seq[Texture]
    textureSize: vec2
    chars: array[16384, Char]
    hichars: Table[Rune, Char]
    kerning: Table[array[2, Rune], float32]

  TextMesh* = object
    s*: string
    font*: Font
    mesh*: Mesh
    width*: float32


proc hash(r: Rune): Hash =
  result = int(r).hash


proc loadFont*(path: string): Font =
  result = Font(textures: newSeq[Texture]())
  result.hichars = initTable[Rune, Char]()
  result.kerning = initTable[array[2, Rune], float32]()

  for line in lines(path):
    let fields = line.split

    var data = initTable[string, string]()
    var lastkey: string
    for f in fields[1..high(fields)]:
      if '=' notin f:
        data[lastkey] = data[lastkey] & f
        continue

      let pair = f.split(sep='=')

      data[pair[0]] = pair[1]
      lastkey = pair[0]

    case fields[0]
    of "info":
      discard
    of "common":
      result.textureSize[0] = data["scaleW"].parseFloat
      result.textureSize[1] = data["scaleH"].parseFloat
    of "page":
      let image = loadPNG32(splitPath(path).head / data["file"][1..^2])
      var texture = newTexture()
      texture.image2d(GL_RGBA8, image.width.int32, image.height.int32, data=image.data)
      texture.generateMipmap()
      texture.filter(true)
      result.textures.add(texture)
    of "char":
      let c = Char(
          id: data["id"].parseInt.Rune,
          pos: [data["x"].parseFloat.float32 / result.textureSize.x, data["y"].parseFloat.float32 / result.textureSize.y],
          size: [data["width"].parseFloat.float32, data["height"].parseFloat.float32],
          offset: [data["xoffset"].parseFloat.float32, data["yoffset"].parseFloat.float32],
          advance: data["xadvance"].parseFloat.float32,
        )
      if int(c.id) >= 16384:
        result.hichars[c.id] = c
      else:
        result.chars[int(c.id)] = c
    of "kerning":
      result.kerning[[data["first"].parseInt.Rune, data["second"].parseInt.Rune]] = data["amount"].parseFloat
    else:
      discard

proc stringMesh(s: string, f: Font, w: var float32): Mesh =
  result = newMesh()

  var x = 0.0'f32

  var lastrune = Rune(0)
  var idx = 0
  for r in runes(s):
    let
      c = if int(r) < 16384: f.chars[int(r)] else: f.hichars[r]
      tw = c.size[0] / f.textureSize[0]
      th = c.size[1] / f.textureSize[1]
      yp = -c.offset[1]
      kernpair = [lastrune, r]
      kern = f.kerning.getOrDefault(kernpair)

    x += kern

    result.vertices.add([
      Vertex(position: [x + c.offset[0],             yp - c.size[1], 0.0], uv: [c.pos[0],      c.pos[1] + th]),
      Vertex(position: [x + c.offset[0],                         yp, 0.0], uv: [c.pos[0],      c.pos[1]]),
      Vertex(position: [x + c.offset[0] + c.size[0],             yp, 0.0], uv: [c.pos[0] + tw, c.pos[1]]),
      Vertex(position: [x + c.offset[0] + c.size[0], yp - c.size[1], 0.0], uv: [c.pos[0] + tw, c.pos[1] + th]),
    ])
    result.indices.add([
      uint32(idx * 4 + 0),
      uint32(idx * 4 + 2),
      uint32(idx * 4 + 1),
      uint32(idx * 4 + 0),
      uint32(idx * 4 + 3),
      uint32(idx * 4 + 2),
    ])

    x += c.advance
    lastrune = r
    idx += 1

  w = x


proc newTextMesh*(f: Font, s: string): TextMesh =
  var w: float32
  var v = stringMesh(s, f, w)
  v.buildBuffers()
  result = TextMesh(
    s: s,
    font: f,
    mesh: v,
    width: w,
  )


proc update*(t: var TextMesh, s: string) =
  if t.s == s:
    return
  t.s = s
  t.mesh.deleteBuffers()
  var w: float32
  var v = stringMesh(s, t.font, w)
  v.buildBuffers()
  t.mesh = v
  t.width = w
