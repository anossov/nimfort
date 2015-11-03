import logging
import strutils
import random
import opengl

import gl/shader
import gl/texture
import gl/framebuffer

import engine/resources
import engine/vector
import engine/camera
import engine/renderer/screen
import engine/mesh


const
  kernelSize = 16
  kernelRadius = 0.3
  noiseSize = 4

type
  SSAO* = ref object
    shader: Program
    blur: Program
    unblurred*: Texture
    occlusion*: Texture
    noise: Texture
    fb: Framebuffer
    fb_blur: Framebuffer


proc newSSAO*(): SSAO =
  var s = getShader("ssao")
  s.use()

  var i = 0
  while i < kernelSize:
    var sample = vec(random(-1.0, 1.0), random(-1.0, 1.0), random(0.0, 1.0))
    let n = sample.norm
    if n > 1.0: continue
    sample = (sample / n) * random(0.0, 1.0)
    var scale = 1.0 / kernelSize
    scale = 0.1 + scale * scale * 0.9

    s.getUniform("kernel[$1]".format(i)).set(sample)
    inc(i)

  s.getUniform("kernelSize").set(kernelSize)
  s.getUniform("radius").set(kernelRadius)
  s.getUniform("invBufferSize").set(Screen.pixelSize)
  s.getUniform("noiseSize").set(noiseSize)
  s.getUniform("depth").set(0)
  s.getUniform("normals").set(1)
  s.getUniform("noise").set(2)

  var blur = getShader("ssao_blur")
  blur.use()
  s.getUniform("invBufferSize").set(Screen.pixelSize)

  var fb = newFramebuffer()
  var t = newTexture2d(Screen.width, Screen.height, TextureFormat.Red, PixelType.Float)
  fb.attach(t)

  var fbb = newFramebuffer()
  var bt = newTexture2d(Screen.width, Screen.height, TextureFormat.Red, PixelType.Float)
  fbb.attach(bt)

  var nt = newTexture()
  nt.filter(false)
  nt.repeat()
  var noise = ""
  for _ in 1..noiseSize * noiseSize:
    var v = vec(random(-1.0, 1.0), random(-1.0, 1.0), 0.0).normalize()

    let p = addr v
    let bytes = cast[cstring](p)

    for i in 0..sizeof(v)-1:
      noise.add(bytes[i])

  nt.image2d(GL_RGB16F, noiseSize, noiseSize, TextureFormat.RGB, PixelType.Float, noise)

  return SSAO(
    shader: s,
    blur: blur,
    fb: fb,
    fb_blur: fbb,
    unblurred: t,
    occlusion: bt,
    noise: nt,
  )


proc perform*(pass: SSAO, depth: Texture, normals: Texture) =
  pass.fb.use()
  glViewport(0, 0, Screen.width, Screen.height)
  glDisable(GL_DEPTH_TEST)
  glDisable(GL_BLEND)

  depth.use(0)
  normals.use(1)
  pass.noise.use(2)
  pass.shader.use()

  let
    V = Camera.getView()
    P = Camera.getProjection()
    PV = P * V
    invPV = PV.inverse
  pass.shader.getUniform("view").set(V)
  pass.shader.getUniform("projection").set(P)
  pass.shader.getUniform("invPV").set(invPV)
  pass.shader.getUniform("normalToView").set(V.inverse.transpose)

  Screen.quad.render()

  pass.fb_blur.use()
  pass.unblurred.use(0)
  pass.blur.use()

  Screen.quad.render()
