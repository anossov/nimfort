import logging
import renderer
import cube
import mesh
import gl/texture
import objfile

type
  World = ref object
    R: RenderSystem
    cube: Mesh
    cubes: seq[Transform]


proc newWorld*(r: RenderSystem): World =
  info("World init start")
  var data = loadObj("assets/bird/bird_decoration.obj")

  result = World(
    R: r,
    cube: newMesh(data, newTexture("assets/bird/bird_decoration_diffuse1024.png")),
    cubes: newSeq[Transform](),
  )
 
  result.R.view = newTransform([0.0'f32, 0.0, 2.0], zero, [1.0'f32, 1.0, 1.0])

  result.cubes.add(newTransform([0.0'f32, 0.0, 0.0], zero, [0.8'f32, 0.8, 0.8]))
  result.cubes.add(newTransform([-1.0'f32, 0.0, 0.0], zero, [0.1'f32, 0.1, 0.1]))

  info("World init end")

proc update*(w: World; time, delta: float) =
  for i, c in mpairs(w.cubes):
    c.rotation = [time.float32 / (i + 2).float32, time / (i + 2).float32, time / (i + 3).float32]
    c.updateMatrix()
    w.R.queue3d.add(Renderable(transform: c, mesh: w.cube))