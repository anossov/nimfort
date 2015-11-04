import engine/vector

type AABB* = object
  min*: vec4
  max*: vec4


proc add*(bb: var AABB, p: vec3) =
  if p.x < bb.min.x: bb.min.x = p.x
  if p.y < bb.min.y: bb.min.y = p.y
  if p.z < bb.min.z: bb.min.z = p.z
  if p.x > bb.max.x: bb.max.x = p.x
  if p.y > bb.max.y: bb.max.y = p.y
  if p.z > bb.max.z: bb.max.z = p.z


proc newAABB*(): AABB = AABB(min: vec(Inf, Inf, Inf, 1.0), max: vec(-Inf, -Inf, -Inf, 1.0))

proc newAABB*(min, max: vec4): AABB = AABB(min: min, max: max)

proc newAABB*(points: openarray[vec3]): AABB =
  result = newAABB()
  for p in points:
    result.add(p)

proc contains*(a: AABB, b: AABB): bool =
  return (
    a.min.x <= b.min.x and
    a.min.y <= b.min.y and
    a.min.z <= b.min.z and
    a.max.x >= b.max.x and
    a.max.y >= b.max.y and
    a.max.z >= b.max.z
  )

proc intersects*(a: AABB, b: AABB): bool =
  if a.max.x < b.min.x: return false
  if a.max.y < b.min.y: return false
  if a.max.z < b.min.z: return false
  if a.min.x > b.max.x: return false
  if a.min.y > b.max.y: return false
  if a.min.z > b.max.z: return false

  return true

proc outside*(a: AABB, b: AABB): bool =
  if a in b: return false
  if a.intersects(b): return false

  return true
