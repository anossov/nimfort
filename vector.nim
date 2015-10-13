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
template z*(v: vec3 | vec4): float32        = v[2]
template w*(v: vec4): float32               = v[3]
template `x=`*(v: vec2 | vec3 | vec4, f: float32) = v[0] = f
template `y=`*(v: vec2 | vec3 | vec4, f: float32) = v[1] = f
template `z=`*(v: vec3 | vec4, f: float32)        = v[2] = f
template `w=`*(v: vec4, f: float32)               = v[3] = f
template value_ptr*(m: var vec2 | vec3 | vec4 | mat3 | mat4): ptr float32 = addr m[0]

proc vec*(x, y: float32): vec2 {.inline.} = 
  result.x = x
  result.y = y

proc vec*(x, y, z: float32): vec3 {.inline.} = 
  result.x = x
  result.y = y
  result.z = z

proc vec*(x, y, z, w: float32): vec4 {.inline.} = 
  result.x = x
  result.y = y
  result.z = z
  result.w = w

const
  xaxis*   = vec(1.0, 0.0, 0.0)
  yaxis*   = vec(0.0, 1.0, 0.0)
  zaxis*   = vec(0.0, 0.0, 1.0)
  zeroes2* = vec(0.0, 0.0)
  zeroes3* = vec(0.0, 0.0, 0.0)
  zeroes4* = vec(0.0, 0.0, 0.0, 0.0)
  ones2*   = vec(1.0, 1.0)
  ones3*   = vec(1.0, 1.0, 1.0)
  ones4*   = vec(1.0, 1.0, 1.0, 1.0)


proc identity*(): mat4 =
  result[0] = 1.0
  result[5] = 1.0
  result[10] = 1.0
  result[15] = 1.0


proc length*(v: vec3): float32 {.inline.} = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)


proc normalize*(v: vec3): vec3 {.inline.} =
  let mag = v.length
  result.x = v.x / mag
  result.y = v.y / mag
  result.z = v.z / mag


proc `-`*(v: vec2): vec2 =
  result.x = -v.x
  result.y = -v.y

proc `-`*(v: vec3): vec3 =
  result.x = -v.x
  result.y = -v.y
  result.z = -v.z


proc `-`*(a, b: vec2): vec2 =
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `-`*(a, b: vec3): vec3 =
  result.x = a.x - b.x
  result.y = a.y - b.y
  result.z = a.z - b.z

proc `-`*(a: vec2, b: float32): vec2 =
  result.x = a.x - b
  result.y = a.y - b

proc `-`*(a: vec3, b: float32): vec3 =
  result.x = a.x - b
  result.y = a.y - b
  result.z = a.z - b


proc `+`*(a, b: vec2): vec2 =
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `+`*(a, b: vec3): vec3 =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z

proc `+`*(a: vec2, b: float32): vec2 =
  result.x = a.x + b
  result.y = a.y + b

proc `+`*(a: vec3, b: float32): vec3 =
  result.x = a.x + b
  result.y = a.y + b
  result.z = a.z + b


proc `*`*(a, b: vec2): vec2 =
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `*`*(a, b: vec3): vec3 =
  result.x = a.x * b.x
  result.y = a.y * b.y
  result.z = a.z * b.z

proc `*`*(a: vec2, b: float32): vec2 =
  result.x = a.x * b
  result.y = a.y * b

proc `*`*(a: vec3, b: float32): vec3 =
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b


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
  result[4] = s.y
  result[8] = s.z
  result[1] = u.x
  result[5] = u.y
  result[9] = u.z
  result[2] = f.x
  result[6] = f.y
  result[10] = f.z
  result[12] = -(s.dot(eye))
  result[13] = -(u.dot(eye))
  result[14] = -(f.dot(eye))
  result[15] = 1.0

# TODO:
# determinant
# inverse
# reflect
# refract
# unproject
# vector angle
# point distance
# vector rotate directly
# quaternions
# noise
# shear?
# splines?