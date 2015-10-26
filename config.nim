const
  windowWidth* = 2200
  windowHeight* = 1200
  windowTitle* = "Nimfort"

  shadowMapSize* = 2048

  bindings* = [
    ("ESC-down", "quit"),

    ("control-KP_ADD-down", "camera.exposure-up"),
    ("control-KP_SUBTRACT-down", "camera.exposure-down"),
  ]

when defined(release):
  const debugContext* = 0
else:
  const debugContext* = 1
