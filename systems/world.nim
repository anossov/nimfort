import logging
import renderer
import mesh
import gl/texture
import objfile
import vector
import timekeeping

type
  World = ref object
    R: RenderSystem
    time: TimeSystem
    cube: Mesh
    cubes: seq[Transform]
    plane: Mesh
    planeT: Transform


proc newWorld*(time: TimeSystem, r: RenderSystem): World =
  info("World init start")
  var data = loadObj("assets/cube.obj")
  var pdata = loadObj("assets/quad.obj")

  result = World(
    R: r,
    time: time,
    cube: newMesh(data, newTexture("assets/test.png")),
    cubes: newSeq[Transform](),
    plane: newMesh(pdata, newTexture("assets/test.png"))
  )
 
  result.R.view = newTransform(vec(0.0, 3.0, 2.0), zeroes3, ones3)

  result.cubes.add(newTransform(vec(0.0, 0.0, 0.0), zeroes3, ones3 * 0.5))
  result.cubes.add(newTransform(vec(-1.0, 0.0, 0.0), zeroes3, ones3 * 0.1))

  result.planeT = newTransform(vec(0.0, -1.0, 0.0), zeroes3, ones3 * 5)

  info("World init end")

proc update*(w: World) =
  for i, c in mpairs(w.cubes):
    let
      f = i.float32
      t = w.time.totalTime
    c.rotation = vec(t / (f + 2.0), t / (f + 2.0), t / (f + 3.0))
    c.updateMatrix()
    w.R.queue3d.add(Renderable(transform: c, mesh: w.cube))

  w.R.queue3d.add(Renderable(transform: w.planeT, mesh: w.plane))