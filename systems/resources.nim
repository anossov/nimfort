import logging
import strutils
import text
import objfile
import mesh
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
    texture = newTexture("assets/textures/$1.png" % name)
  newMesh(data, texture)