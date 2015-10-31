import logging

const
  windowWidth*    = 1600
  windowHeight*   = 1200
  windowTitle*    = "Nimfort"

  shadowMapSize*  = 2048

  bindings*       = [
    ("ESCAPE-down", "quit"),

    ("control-KP_ADD-down", "camera.exposure-up"),
    ("control-KP_SUBTRACT-down", "camera.exposure-down"),

    ("LMB-down", "camera.pick"),
    ("RMB-down", "camera.drag"),
    ("RMB-up", "camera.release"),

    ("ENTER-down", "console.submit"),
    ("KP_ENTER-down", "console.submit"),
    ("BACKSPACE-down", "console.erase"),
    ("BACKSPACE-repeat", "console.erase"),
  ]

  bloomScale*     = 3
  bloomThreshold* = 3.0
  bloomPasses*    = 2

when defined(release):
  const
    debugContext* = 0
    logLevel* = lvlInfo
else:
  const
    debugContext* = 1
    logLevel* = lvlAll
