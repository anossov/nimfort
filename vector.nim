import logging
import opengl
import math
import strutils

type
  vec2* {.bycopy pure.} = array[2, float32]
  vec3* {.bycopy pure.} = array[3, float32]
  vec4* {.bycopy pure.} = array[4, float32]
  mat3* {.bycopy pure.} = array[9, float32]
  mat4* {.bycopy pure.} = array[16, float32]

  ivec2* {.bycopy pure.} = array[2, int32]
  ivec3* {.bycopy pure.} = array[3, int32]

template x*(v: vec2 | vec3 | vec4): float32 = v[0]
template y*(v: vec2 | vec3 | vec4): float32 = v[1]
template z*(v: vec3 | vec4): float32        = v[2]
template w*(v: vec4): float32               = v[3]
template `x=`*(v: vec2 | vec3 | vec4, f: float32) = v[0] = f
template `y=`*(v: vec2 | vec3 | vec4, f: float32) = v[1] = f
template `z=`*(v: vec3 | vec4, f: float32)        = v[2] = f
template `w=`*(v: vec4, f: float32)               = v[3] = f
template value_ptr*(m: var vec2 | vec3 | vec4 | mat3 | mat4): ptr float32 = addr m[0]

template x*(v: ivec2 | ivec3): int32 = v[0]
template y*(v: ivec2 | ivec3): int32 = v[1]
template z*(v: ivec3): int32 = v[2]
template `x=`*(v: ivec2 | ivec3, i: int32) = v[0] = i
template `y=`*(v: ivec2 | ivec3, i: int32) = v[1] = i
template `z=`*(v: ivec3, i: int32) = v[2] = i

template xyz*(v: vec4): vec3 = vec(v.x, v.y, v.z)

proc `$`*(v: vec2): string = "($1, $2)".format(v.x, v.y)
proc `$`*(v: vec3): string = "($1, $2, $3)".format(v.x, v.y, v.z)
proc `$`*(v: vec4): string = "($1, $2, $3, $4)".format(v.x, v.y, v.z, v.w)
proc `$`*(v: ivec2): string = "($1, $2)".format(v.x, v.y)
proc `$`*(v: ivec3): string = "($1, $2, $3)".format(v.x, v.y, v.z)

proc vec*(x, y: float32): vec2 {.inline.} =
  result.x = x
  result.y = y

proc ivec*(x, y: int32): ivec2 {.inline.} =
  result.x = x
  result.y = y

proc ivec*(x, y, z: int32): ivec3 {.inline.} =
  result.x = x
  result.y = y
  result.z = z

proc ivec*(x, y, z: int): ivec3 {.inline.} =
  result.x = x.int32
  result.y = y.int32
  result.z = z.int32

proc vec*(x, y, z: float32): vec3 {.inline.} =
  result.x = x
  result.y = y
  result.z = z

proc vec*(x, y, z, w: float32): vec4 {.inline.} =
  result.x = x
  result.y = y
  result.z = z
  result.w = w

proc vec*(v: vec2, z: float32): vec3 {.inline} =
  result.x = v.x
  result.y = v.y
  result.z = z

proc vec*(v: vec3, w: float32): vec4 {.inline} =
  result.x = v.x
  result.y = v.y
  result.z = v.z
  result.w = w

proc toFloat*(v: ivec2): vec2 {.inline.} =
  result.x = v.x.float32
  result.y = v.y.float32

proc toFloat*(v: ivec3): vec3 {.inline.} =
  result.x = v.x.float32
  result.y = v.y.float32
  result.z = v.z.float32

proc mat*(c1, c2, c3, c4: vec4): mat4 =
  result[0..3] = c1
  result[4..7] = c2
  result[8..11] = c3
  result[12..15] = c4

proc mat_from_rows*(r1, r2, r3, r4: vec4): mat4 =
  mat(
    vec(r1.x, r2.x, r3.x, r4.x),
    vec(r1.y, r2.y, r3.y, r4.y),
    vec(r1.z, r2.z, r3.z, r4.z),
    vec(r1.w, r2.w, r3.w, r4.w),
  )

const
  xaxis*   = vec(1.0, 0.0, 0.0)
  yaxis*   = vec(0.0, 1.0, 0.0)
  zaxis*   = vec(0.0, 0.0, 1.0)
  negzaxis*   = vec(0.0, 0.0, -1.0)
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


proc inverse*(v: vec2): vec2 {.inline.} =
  result.x = 1.0 / v.x
  result.y = 1.0 / v.y

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

proc `-`*(a, b: vec4): vec4 =
  result.x = a.x - b.x
  result.y = a.y - b.y
  result.z = a.z - b.z
  result.w = a.w - b.w

proc `-`*(a: vec2, b: float32): vec2 =
  result.x = a.x - b
  result.y = a.y - b

proc `-`*(a: vec3, b: float32): vec3 =
  result.x = a.x - b
  result.y = a.y - b
  result.z = a.z - b

proc `-`*(a: vec4, b: float32): vec4 =
  result.x = a.x - b
  result.y = a.y - b
  result.z = a.z - b
  result.w = a.w - b


proc `+`*(a, b: vec2): vec2 =
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `+`*(a, b: vec3): vec3 =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z

proc `+`*(a, b: vec4): vec4 =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z
  result.w = a.w + b.w

proc `+`*(a: vec2, b: float32): vec2 =
  result.x = a.x + b
  result.y = a.y + b

proc `+`*(a: vec3, b: float32): vec3 =
  result.x = a.x + b
  result.y = a.y + b
  result.z = a.z + b

proc `+`*(a: vec4, b: float32): vec4 =
  result.x = a.x + b
  result.y = a.y + b
  result.z = a.z + b
  result.w = a.w + b


proc `*`*(a, b: vec2): vec2 =
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `*`*(a, b: vec3): vec3 =
  result.x = a.x * b.x
  result.y = a.y * b.y
  result.z = a.z * b.z

proc `*`*(a, b: vec4): vec4 =
  result.x = a.x * b.x
  result.y = a.y * b.y
  result.z = a.z * b.z
  result.w = a.w * b.w

proc `*`*(a: vec2, b: float32): vec2 =
  result.x = a.x * b
  result.y = a.y * b

proc `*`*(a: vec3, b: float32): vec3 =
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b

proc `*`*(a: vec4, b: float32): vec4 =
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b
  result.w = a.w * b


proc `*`*(a: mat4, b: float32): mat4 =
  result[0] = a[0] * b
  result[1] = a[1] * b
  result[2] = a[2] * b
  result[3] = a[3] * b
  result[4] = a[4] * b
  result[5] = a[5] * b
  result[6] = a[6] * b
  result[7] = a[7] * b
  result[8] = a[8] * b
  result[9] = a[9] * b
  result[10] = a[10] * b
  result[11] = a[11] * b
  result[12] = a[12] * b
  result[13] = a[13] * b
  result[14] = a[14] * b
  result[15] = a[15] * b


proc `/`*(a: vec3, b: float32): vec3 =
  result.x = a.x / b
  result.y = a.y / b
  result.z = a.z / b

proc `/`*(a: vec4, b: float32): vec4 =
  result.x = a.x / b
  result.y = a.y / b
  result.z = a.z / b
  result.w = a.w / b


proc `dot`*(a, b: vec3): float32 =
  var t = a * b
  result = t.x + t.y + t.z

proc `cross`*(a, b: vec3): vec3 =
  result[0] = a.y * b.z - b.y * a.z
  result[1] = a.z * b.x - b.z * a.x
  result[2] = a.x * b.y - b.x * a.y

proc norm*(v: vec3): float32 {.inline.} = sqrt(v.dot(v))

proc normalize*(v: vec3): vec3 {.inline.} =
  let mag = v.norm
  result.x = v.x / mag
  result.y = v.y / mag
  result.z = v.z / mag

proc angle*(a, b: vec3): float32 = arccos(a.dot(b) / (a.norm * b.norm))

proc distance*(a, b: vec3): float32 = norm(b - a)

proc projectOn*(a, b: vec3): vec3 =
  result = b * a.dot(b)

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

proc radians*(d: float32): float32 {.inline.} = d * PI / 180.0

proc perspective*(fov, aspect, near, far: float32): mat4 =
  result[5] = 1.0 / tan(radians(fov) / 2)
  result[0] = result[5] / aspect
  result[10] = -(far + near) / (far - near)
  result[14] = -(2.0 * far * near) / (far - near)
  result[11] = -1.0

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
  result[2] = -f.x
  result[6] = -f.y
  result[10] = -f.z
  result[12] = -(s.dot(eye))
  result[13] = -(u.dot(eye))
  result[14] = (f.dot(eye))
  result[15] = 1.0

proc inverse*(m: mat4): mat4 =
  let
    Coef00 = m[10] * m[15] - m[14] * m[11]
    Coef02 = m[6] * m[15] - m[14] * m[7]
    Coef03 = m[6] * m[11] - m[10] * m[7]

    Coef04 = m[9] * m[15] - m[13] * m[11]
    Coef06 = m[5] * m[15] - m[13] * m[7]
    Coef07 = m[5] * m[11] - m[9] * m[7]

    Coef08 = m[9] * m[14] - m[13] * m[10]
    Coef10 = m[5] * m[14] - m[13] * m[6]
    Coef11 = m[5] * m[10] - m[9] * m[6]

    Coef12 = m[8] * m[15] - m[12] * m[11]
    Coef14 = m[4] * m[15] - m[12] * m[7]
    Coef15 = m[4] * m[11] - m[8] * m[7]

    Coef16 = m[8] * m[14] - m[12] * m[10]
    Coef18 = m[4] * m[14] - m[12] * m[6]
    Coef19 = m[4] * m[10] - m[8] * m[6]

    Coef20 = m[8] * m[13] - m[12] * m[9]
    Coef22 = m[4] * m[13] - m[12] * m[5]
    Coef23 = m[4] * m[9] - m[8] * m[5]

    Fac0 = vec(Coef00, Coef00, Coef02, Coef03)
    Fac1 = vec(Coef04, Coef04, Coef06, Coef07)
    Fac2 = vec(Coef08, Coef08, Coef10, Coef11)
    Fac3 = vec(Coef12, Coef12, Coef14, Coef15)
    Fac4 = vec(Coef16, Coef16, Coef18, Coef19)
    Fac5 = vec(Coef20, Coef20, Coef22, Coef23)

    Vec0 = vec(m[4], m[0], m[0], m[0])
    Vec1 = vec(m[5], m[1], m[1], m[1])
    Vec2 = vec(m[6], m[2], m[2], m[2])
    Vec3 = vec(m[7], m[3], m[3], m[3])

    Inv0 = Vec1 * Fac0 - Vec2 * Fac1 + Vec3 * Fac2
    Inv1 = Vec0 * Fac0 - Vec2 * Fac3 + Vec3 * Fac4
    Inv2 = Vec0 * Fac1 - Vec1 * Fac3 + Vec3 * Fac5
    Inv3 = Vec0 * Fac2 - Vec1 * Fac4 + Vec2 * Fac5

    SignA = vec(+1, -1, +1, -1)
    SignB = vec(-1, +1, -1, +1)

    Inverse = mat(Inv0 * SignA, Inv1 * SignB, Inv2 * SignA, Inv3 * SignB)

    Row0 = vec(Inverse[0], Inverse[4], Inverse[8], Inverse[12])
    Dot0 = vec(m[0], m[1], m[2], m[3]) * Row0

    Dot1 = (Dot0.x + Dot0.y) + (Dot0.z + Dot0.w)

    OneOverDeterminant = 1.0 / Dot1

  result = Inverse * OneOverDeterminant


proc project*(point: vec3, PV: mat4, viewport: vec4): vec3 =
  var tmp = PV * vec(point, 1.0)
  tmp = tmp / tmp.w;
  tmp = tmp * 0.5 + 0.5
  tmp[0] = tmp[0] * viewport[2] + viewport[0]
  tmp[1] = tmp[1] * viewport[3] + viewport[1]

  result = tmp.xyz


proc unproject*(point: vec3, PV: mat4, viewport: vec4): vec3 =
  let Inverse = inverse(PV)

  var tmp = vec(point, 1.0)

  tmp.x = (tmp.x - viewport[0]) / viewport[2]
  tmp.y = (tmp.y - viewport[1]) / viewport[3]
  tmp = tmp * 2.0 - 1.0

  tmp = Inverse * tmp
  result = tmp.xyz / tmp.w


# TODO:
# determinant
# reflect
# refract
# point distance
# vector rotate directly
# quaternions
# noise
# shear?
# splines?
