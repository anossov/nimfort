const
  windowWidth* = 1600
  windowHeight* = 1200
  windowTitle* = "Nimfort"
  MSAASamples* = 4

  shadowMapSize* = 2048

when defined(release):
  const debugContext* = 0
else:
  const debugContext* = 1