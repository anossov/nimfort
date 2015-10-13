import opengl
import math

type
  vec2* = array[2, float32]
  vec3* = array[3, float32]
  vec4* = array[4, float32]
  mat3* = array[9, float32]
  mat4* = array[16, float32]

template x*(v: vec2 | vec3 | vec4): float32 = v[0]
template y*(v: vec2 | vec3 | vec4): float32 = v[1]
template z*(v: vec3 | vec4): float32 = v[2]
template value_ptr*(m: var vec3 | mat4): ptr float32 = addr m[0]

proc vec*(x, y: float32): vec2 {.inline.} = 
  result[0] = x
  result[1] = y

proc vec*(x, y, z: float32): vec3 {.inline.} = 
  result[0] = x
  result[1] = y
  result[2] = z

proc vec*(x, y, z, w: float32): vec4 {.inline.} = 
  result[0] = x
  result[1] = y
  result[2] = z
  result[3] = w

const
  xaxis* = vec(1.0, 0.0, 0.0)
  yaxis* = vec(0.0, 1.0, 0.0)
  zaxis* = vec(0.0, 0.0, 1.0)

proc zeros2*(): vec2 = return
proc zeros3*(): vec3 = return
proc zeros4*(): vec4 = return

proc ones2*(): vec2 = result = vec(1.0, 1.0)
proc ones3*(): vec3 = result = vec(1.0, 1.0, 1.0)
proc ones4*(): vec4 = result = vec(1.0, 1.0, 1.0, 1.0)

proc identity*(): mat4 =
  result[0] = 1.0
  result[5] = 1.0
  result[10] = 1.0
  result[15] = 1.0

proc normalize*(v: vec3): vec3 {.inline.} =
  let mag = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
  result[0] = v.x / mag
  result[1] = v.y / mag
  result[2] = v.z / mag

proc `-`*(v: vec3): vec3 =
  result[0] = -v.x
  result[1] = -v.y
  result[2] = -v.z

proc `-`*(a, b: vec3): vec3 =
  result[0] = a.x - b.x
  result[1] = a.y - b.y
  result[2] = a.z - b.z

proc `+`*(a, b: vec3): vec3 =
  result[0] = a.x + b.x
  result[1] = a.y + b.y
  result[2] = a.z + b.z

proc `*`*(a, b: vec3): vec3 =
  result[0] = a.x * b.x
  result[1] = a.y * b.y
  result[2] = a.z * b.z


proc `cross`*(a, b: vec3): vec3 =
  result[0] = a.y * b.z - b.y * a.z
  result[1] = a.z * b.x - b.z * a.x
  result[2] = a.x * b.y - b.x * a.y

proc `dot`*(a, b: vec3): float32 =
  var t = a * b
  result = t.x + t.y + t.z

proc `*`*(a: mat4, b: vec4): vec4 =
  result[0] = a[0] * b[0] + a[4] * b[1] + a[8] * b[2] + a[12] * b[3]
  result[1] = a[1] * b[0] + a[5] * b[1] + a[9] * b[2] + a[13] * b[3]
  result[2] = a[2] * b[0] + a[6] * b[1] + a[10] * b[2] + a[14] * b[3]
  result[3] = a[3] * b[0] + a[7] * b[1] + a[11] * b[2] + a[15] * b[3]

proc `*`*(a: mat4, b: mat4): mat4 =
  result[0]  = a[0] *  b[0] + a[4] *  b[1] +  a[8] *  b[2] + a[12] *  b[3]
  result[1]  = a[1] *  b[0] + a[5] *  b[1] +  a[9] *  b[2] + a[13] *  b[3]
  result[2]  = a[2] *  b[0] + a[6] *  b[1] + a[10] *  b[2] + a[14] *  b[3]
  result[3]  = a[3] *  b[0] + a[7] *  b[1] + a[11] *  b[2] + a[15] *  b[3]
  
  result[4]  = a[0] *  b[4] + a[4] *  b[5] +  a[8] *  b[6] + a[12] *  b[7]
  result[5]  = a[1] *  b[4] + a[5] *  b[5] +  a[9] *  b[6] + a[13] *  b[7]
  result[6]  = a[2] *  b[4] + a[6] *  b[5] + a[10] *  b[6] + a[14] *  b[7]
  result[7]  = a[3] *  b[4] + a[7] *  b[5] + a[11] *  b[6] + a[15] *  b[7]
  
  result[8]  = a[0] *  b[8] + a[4] *  b[9] +  a[8] * b[10] + a[12] * b[11]
  result[9]  = a[1] *  b[8] + a[5] *  b[9] +  a[9] * b[10] + a[13] * b[11]
  result[10] = a[2] *  b[8] + a[6] *  b[9] + a[10] * b[10] + a[14] * b[11]
  result[11] = a[3] *  b[8] + a[7] *  b[9] + a[11] * b[10] + a[15] * b[11]
  
  result[12] = a[0] * b[12] + a[4] * b[13] +  a[8] * b[14] + a[12] * b[15]
  result[13] = a[1] * b[12] + a[5] * b[13] +  a[9] * b[14] + a[13] * b[15]
  result[14] = a[2] * b[12] + a[6] * b[13] + a[10] * b[14] + a[14] * b[15]
  result[15] = a[3] * b[12] + a[7] * b[13] + a[11] * b[14] + a[15] * b[15]


proc rotate*(axis: vec3, angle: float32): mat4 =
  let
    c = cos(angle)
    s = sin(angle)
    ic = 1.0 - c
    a = axis.normalize
  
  result[0] = c + a.x * a.x * ic
  result[4] = a.x * a.y * ic - a.z * s
  result[8] = a.x * a.z * ic + a.y * s
  result[1] = a.y * a.x * ic + a.z * s
  result[5] = c + a.y * a.y * ic
  result[9] = a.y * a.z * ic - a.x * s
  result[2] = a.z * a.x * ic - a.y * s
  result[6] = a.z * a.y * ic + a.x * s
  result[10] = c + a.z * a.z * ic
  result[15] = 1.0


proc translate*(v: vec3): mat4 = 
  result[0] = 1.0
  result[5] = 1.0
  result[10] = 1.0
  result[12] = v.x
  result[13] = v.y
  result[14] = v.z
  result[15] = 1.0

proc scale*(s: float32): mat4 = 
  result[0] = s
  result[5] = s
  result[10] = s
  result[15] = 1.0

proc scale*(s: vec3): mat4 = 
  result[0] = s.x
  result[5] = s.y
  result[10] = s.z
  result[15] = 1.0

proc perspective*(fov, aspect, near, far: float32): mat4 =
  result[5] = 1.0 / tan(fov * PI / 360.0)
  result[0] = result[5] / aspect
  result[10] = (-near - far) / (near - far)
  result[14] = (2.0 * far * near) / (near - far)
  result[11] = 1.0

proc orthographic*(left, right, bottom, top, near, far: float32): mat4 =
  result[0] = 2.0 / (right - left)
  result[5] = 2.0 / (top - bottom)
  result[10] = -2.0 / (far - near)
  result[12] = -(right + left) / (right - left)
  result[13] = -(top + bottom) / (top - bottom)
  result[14] = -(far + near) / (far - near)
  result[15] = 1.0

proc orthographic*(left, right, bottom, top: float32): mat4 =
  result[0] = 2.0 / (right - left)
  result[5] = 2.0 / (top - bottom)
  result[10] = -1
  result[12] = -(right + left) / (right - left)
  result[13] = -(top + bottom) / (top - bottom)
  result[15] = 1.0

proc lookAt*(eye, center, up: vec3): mat4 =
  let
    f = normalize(center - eye)
    s = normalize(f.cross(up))
    u = s.cross(f)

  result[0] = s.x
  result[1] = s.y
  result[2] = s.z
  result[4] = u.x
  result[5] = u.y
  result[6] = u.z
  result[8] = f.x
  result[9] = f.y
  result[10] = f.z
  result[12] = -(s.dot(eye))
  result[13] = -(u.dot(eye))
  result[14] = -(f.dot(eye))
  result[15] = 1.0