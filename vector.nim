import opengl
import math

type
  vec2*[T] = array[2, T]
  vec3*[T] = array[3, T]
  vec4*[T] = array[4, T]
  mat3*[T] = array[9, T]
  mat4*[T] = array[16, T]


proc identity*[T](): mat4[T] =
  result[0] = 1.0
  result[5] = 1.0
  result[10] = 1.0
  result[15] = 1.0

proc normalize*[T](v: vec3[T]): vec3[T] {.inline.} =
  let mag = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
  result[0] = v.x / mag
  result[1] = v.y / mag
  result[2] = v.z / mag

proc `-`*[T](v: vec3[T]): vec3[T] =
  result[0] = -v.x
  result[1] = -v.y
  result[2] = -v.z

proc `*`*[T](a: mat4[T], b: vec4[T]): vec4[T] =
  result[0] = a[0] * b[0] + a[4] * b[1] + a[8] * b[2] + a[12] * b[3]
  result[1] = a[1] * b[0] + a[5] * b[1] + a[9] * b[2] + a[13] * b[3]
  result[2] = a[2] * b[0] + a[6] * b[1] + a[10] * b[2] + a[14] * b[3]
  result[3] = a[3] * b[0] + a[7] * b[1] + a[11] * b[2] + a[15] * b[3]

proc `*`*[T](a: mat4[T], b: mat4[T]): mat4[T] =
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


proc rotate*[T](axis: vec3[T], angle: T): mat4[T] =
  let
    c = cos(angle)
    s = sin(angle)
    ic = 1.T - c
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


proc translate*[T](v: vec3[T]): mat4[T] = 
  result[0] = 1.0
  result[5] = 1.0
  result[10] = 1.0
  result[12] = v.x
  result[13] = v.y
  result[14] = v.z
  result[15] = 1.0

proc scale*[T](s: T): mat4[T] = 
  result[0] = s
  result[5] = s
  result[10] = s
  result[15] = 1.0

proc scale*[T](s: vec3[T]): mat4[T] = 
  result[0] = s.x
  result[5] = s.y
  result[10] = s.z
  result[15] = 1.0

proc perspective*[T](fov, aspect, near, far: T): mat4[T] =
  result[5] = 1.0 / tan(fov * PI / 360.0)
  result[0] = result[5] / aspect
  result[10] = (-near - far) / (near - far)
  result[14] = (2.0 * far * near) / (near - far)
  result[11] = 1.0

proc orthographic*[T](left, right, bottom, top, near, far: T): mat4[T] =
  result[0] = 2.0 / (right - left)
  result[5] = 2.0 / (top - bottom)
  result[10] = -2.0 / (far - near)
  result[12] = -(right + left) / (right - left)
  result[13] = -(top + bottom) / (top - bottom)
  result[14] = -(far + near) / (far - near)
  result[15] = 1.0

proc orthographic*[T](left, right, bottom, top: T): mat4[T] =
  result[0] = 2.0 / (right - left)
  result[5] = 2.0 / (top - bottom)
  result[10] = -1
  result[12] = -(right + left) / (right - left)
  result[13] = -(top + bottom) / (top - bottom)
  result[15] = 1.0


template x*[T](v: vec2[T] | vec3[T] | vec4[T]): T = v[0]

template y*[T](v: vec2[T] | vec3[T] | vec4[T]): T = v[1]

template z*[T](v: vec3[T] | vec4[T]): T = v[2]

template value_ptr*[T](m: var vec3[T] | mat4[T]): ptr T = addr m[0]