import logging
import systems/ecs
import systems/timekeeping
import vector
import math
import random

type
  Transform* = object of Component
    position*: vec3
    forward*: vec3
    side: vec3
    up*: vec3
    scale*: vec3
    matrix*: mat4

  Animation* = object of Component
    tFrom*: Transform
    tTo*: Transform
    duration*: float
    done*: bool
    time: float

  LookAtConstraint* = object of Component
    target*: vec3

  CircleMovement* = object of Component
    axis*: vec3
    rvector*: vec3
    center*: vec3
    period*: float32

  RandomMovement* = object of Component
    min*: vec3
    max*: vec3
    smin*: float
    smax*: float

  Bounce* = object of Component
    min*: float
    max*: float
    period*: float


proc updateMatrix*(t: var Transform) =
  let p = t.position
  t.matrix = mat(
    vec(t.side, 0.0),
    vec(t.up, 0.0),
    vec(-t.forward, 0.0),
    vec(p, 1.0),
  ) * scale(t.scale)

proc newTransform*(p=zeroes3, f=negzaxis, u=yaxis, s=ones3): Transform =
  result.position = p
  result.forward = f.normalize()
  result.up = u.normalize()
  result.side = result.forward.cross(result.up).normalize()
  result.up = result.side.cross(result.forward).normalize()
  result.scale = s
  result.updateMatrix()

proc newTransform*(p=zeroes3, f=negzaxis, u=yaxis, s: float32): Transform {.inline.} = newTransform(p, f, u, vec(s, s, s))

proc setForward*(t: var Transform, f: vec3) =
  t.forward = f.normalize()
  t.up = t.side.cross(t.forward).normalize()
  t.side = t.forward.cross(t.up).normalize()

proc setUp*(t: var Transform, f: vec3) =
  t.up = f.normalize()
  t.side = t.forward.cross(t.up).normalize()
  t.forward = t.up.cross(t.side).normalize()


proc getView*(t: Transform): mat4 =
  return lookAt(t.position, t.position + t.forward, t.up)


ImplementComponent(Transform, transform)
ImplementComponent(LookAtConstraint, lookat)
ImplementComponent(CircleMovement, circleMovement)
ImplementComponent(RandomMovement, randomMovement)
ImplementComponent(Animation, animation)
ImplementComponent(Bounce, bounce)


proc animate*(t: Transform, p: vec3, duration: float) =
  if not t.entity.has("Animation"):
    t.entity.attach(Animation())

  t.entity.animation.tFrom = t
  t.entity.animation.tTo = t
  t.entity.animation.tTo.position = p
  t.entity.animation.duration = duration
  t.entity.animation.done = false
  t.entity.animation.time = 0.0


proc updateTransforms*() =
  for i in circleMovementStore.data:
    let
      angle = Time.totalTime * 2 * PI / i.period
      p = vec(i.center + i.rvector, 1.0)
      t = rotate(i.axis, angle)
    i.entity.transform.position = (t * p).xyz
    i.entity.transform.updateMatrix()

  for i in lookatStore.data:
    i.entity.transform.setForward(i.target - i.entity.transform.position)
    i.entity.transform.updateMatrix()

  for i in mitems(animationStore.data):
    if i.done:
      continue

    i.time += Time.delta
    if i.time > i.duration:
      i.done = true
      i.entity.transform.position = i.tTo.position
    else:
      let progress = i.time / i.duration
      let distance = i.tTo.position - i.tFrom.position
      i.entity.transform.position = i.tFrom.position + distance * progress

    i.entity.transform.updateMatrix()

  for i in randomMovementStore.data:
    if i.entity.animation.done:
      let
        x = random(i.min.x, i.max.x)
        y = random(i.min.y, i.max.y)
        z = random(i.min.z, i.max.z)
        t = vec(x, y, z)
        s = random(i.smin, i.smax)
        d = distance(i.entity.transform.position, t)
      i.entity.transform.animate(p=t, duration=d / s)

  for i in bounceStore.data:
    let t = sin(Time.totalTime * 2 * PI / i.period)
    i.entity.transform.position.y = i.min + (i.max - i.min) * t
    i.entity.transform.updateMatrix()
