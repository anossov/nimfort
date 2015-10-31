import systems/windowing
import vector
import mesh

type ScreenInfo = ref object
  size*: vec2
  pixelSize*: vec2
  width*: int32
  height*: int32
  viewport*: vec4
  aspectRatio*: float
  projection*: mat4
  quad*: Mesh


var Screen*: ScreenInfo


proc initScreen*() =
  let size = windowSize()

  var quad = newMesh()
  quad.vertices = @[
    Vertex(position: [-1.0'f32, -1.0, -1.0], uv: [0.0'f32, 0.0]),
    Vertex(position: [ 1.0'f32, -1.0, -1.0], uv: [1.0'f32, 0.0]),
    Vertex(position: [ 1.0'f32,  1.0, -1.0], uv: [1.0'f32, 1.0]),
    Vertex(position: [-1.0'f32,  1.0, -1.0], uv: [0.0'f32, 1.0]),
  ]
  quad.indices = @[0'u32, 1, 2, 2, 3, 0]
  quad.buildBuffers()

  Screen = ScreenInfo(
    size: size,
    width: size.x.int32,
    height: size.y.int32,
    viewport: vec(0.0, 0.0, size.x, size.y),
    aspectRatio: size.x / size.y,
    pixelSize: vec(1.0 / size.x, 1.0 / size.y),
    projection: orthographic(0.0, size.x, 0.0, size.y),
    quad: quad,
  )
