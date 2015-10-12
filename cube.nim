import opengl

var cubeVertices* = @[
  -0.5'f32, -0.5, -0.5,  0.0, 0.0,  0.0, 0.0, -1.0,
   0.5, -0.5, -0.5,  1.0, 0.0,  0.0, 0.0, -1.0,
   0.5,  0.5, -0.5,  1.0, 1.0,  0.0, 0.0, -1.0,
   0.5,  0.5, -0.5,  1.0, 1.0,  0.0, 0.0, -1.0,
  -0.5,  0.5, -0.5,  0.0, 1.0,  0.0, 0.0, -1.0,
  -0.5, -0.5, -0.5,  0.0, 0.0,  0.0, 0.0, -1.0,

  -0.5, -0.5,  0.5,  0.0, 0.0,  0.0, 0.0, 1.0,
   0.5, -0.5,  0.5,  1.0, 0.0,  0.0, 0.0, 1.0,
   0.5,  0.5,  0.5,  1.0, 1.0,  0.0, 0.0, 1.0,
   0.5,  0.5,  0.5,  1.0, 1.0,  0.0, 0.0, 1.0,
  -0.5,  0.5,  0.5,  0.0, 1.0,  0.0, 0.0, 1.0,
  -0.5, -0.5,  0.5,  0.0, 0.0,  0.0, 0.0, 1.0,

  -0.5,  0.5,  0.5,  1.0, 0.0,  -1.0, 0.0, 0.0,
  -0.5,  0.5, -0.5,  1.0, 1.0,  -1.0, 0.0, 0.0,
  -0.5, -0.5, -0.5,  0.0, 1.0,  -1.0, 0.0, 0.0,
  -0.5, -0.5, -0.5,  0.0, 1.0,  -1.0, 0.0, 0.0,
  -0.5, -0.5,  0.5,  0.0, 0.0,  -1.0, 0.0, 0.0,
  -0.5,  0.5,  0.5,  1.0, 0.0,  -1.0, 0.0, 0.0,

   0.5,  0.5,  0.5,  1.0, 0.0,  1.0, 0.0, 0.0,
   0.5,  0.5, -0.5,  1.0, 1.0,  1.0, 0.0, 0.0,
   0.5, -0.5, -0.5,  0.0, 1.0,  1.0, 0.0, 0.0,
   0.5, -0.5, -0.5,  0.0, 1.0,  1.0, 0.0, 0.0,
   0.5, -0.5,  0.5,  0.0, 0.0,  1.0, 0.0, 0.0,
   0.5,  0.5,  0.5,  1.0, 0.0,  1.0, 0.0, 0.0,

  -0.5, -0.5, -0.5,  0.0, 1.0,  0.0, -1.0, 0.0,
   0.5, -0.5, -0.5,  1.0, 1.0,  0.0, -1.0, 0.0,
   0.5, -0.5,  0.5,  1.0, 0.0,  0.0, -1.0, 0.0,
   0.5, -0.5,  0.5,  1.0, 0.0,  0.0, -1.0, 0.0,
  -0.5, -0.5,  0.5,  0.0, 0.0,  0.0, -1.0, 0.0,
  -0.5, -0.5, -0.5,  0.0, 1.0,  0.0, -1.0, 0.0,

  -0.5,  0.5, -0.5,  0.0, 1.0,  0.0, 1.0, 0.0,
   0.5,  0.5, -0.5,  1.0, 1.0,  0.0, 1.0, 0.0,
   0.5,  0.5,  0.5,  1.0, 0.0,  0.0, 1.0, 0.0,
   0.5,  0.5,  0.5,  1.0, 0.0,  0.0, 1.0, 0.0,
  -0.5,  0.5,  0.5,  0.0, 0.0,  0.0, 1.0, 0.0,
  -0.5,  0.5, -0.5,  0.0, 1.0,  0.0, 1.0, 0.0,
]