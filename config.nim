const
  windowWidth* = 1600
  windowHeight* = 1200
  windowTitle* = "Nimfort"

  shadowMapSize* = 2048

  bindings* = [
    ("Q-down", "quit"),
    ("W-down", "wire-on"),
    ("W-up", "wire-off"),

    ("KP_ADD-down", "exposure-up"),
    ("KP_SUBTRACT-down", "exposure-down"),
  ]

when defined(release):
  const debugContext* = 0
else:
  const debugContext* = 1


