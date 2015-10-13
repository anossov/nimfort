import logging
import renderer
import mesh
import gl/texture
import objfile
import vector

type
  World = ref object
    R: RenderSystem
    cube: Mesh
    cubes: seq[Transform]


proc newWorld*(r: RenderSystem): World =
  info("World init start")
  var data = loadObj("assets/cube.obj")

  result = World(
    R: r,
    cube: newMesh(data, newTexture("assets/test.png")),
    cubes: newSeq[Transform](),
  )
 
  result.R.view = newTransform(vec(0.0, 0.0, 2.0), zeros3(), vec(1.0, 1.0, 1.0))

  result.cubes.add(newTransform(vec(0.0, 0.0, 0.0), zeros3(), vec(0.5, 0.5, 0.5)))
  result.cubes.add(newTransform(vec(-1.0, 0.0, 0.0), zeros3(), vec(0.1, 0.1, 0.1)))

  info("World init end")

proc update*(w: World; time, delta: float) =
  for i, c in mpairs(w.cubes):
    let f = i.float32
    c.rotation = vec(time / (f + 2.0), time / (f + 2.0), time / (f + 3.0))
    c.updateMatrix()
    w.R.queue3d.add(Renderable(transform: c, mesh: w.cube))