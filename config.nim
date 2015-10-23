const
  windowWidth* = 1600
  windowHeight* = 1200
  windowTitle* = "Nimfort"

  shadowMapSize* = 2048

  bindings* = [
    ("Q-down", "quit"),
    ("W-down", "debug.wire"),
    ("A-down", "debug.albedo"),
    ("R-down", "debug.roughness"),
    ("M-down", "debug.metalness"),
    ("N-down", "debug.normal"),
    ("E-down", "debug.edges"),

    ("KP_ADD-down", "camera.exposure-up"),
    ("KP_SUBTRACT-down", "camera.exposure-down"),
  ]

when defined(release):
  const debugContext* = 0
else:
  const debugContext* = 1
