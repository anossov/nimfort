import opengl

type
  TextureTarget* {.pure.} = enum
    t1D                 = GL_TEXTURE_1D,                   # 0x0DE0
    t2D                 = GL_TEXTURE_2D,                   # 0x0DE1
    t3D                 = GL_TEXTURE_3D,                   # 0x806F
    tRectangle          = GL_TEXTURE_RECTANGLE,            # 0x84F5
    tCubeMap            = GL_TEXTURE_CUBE_MAP,             # 0x8513
    t1DArray            = GL_TEXTURE_1D_ARRAY,             # 0x8C18
    t2DArray            = GL_TEXTURE_2D_ARRAY,             # 0x8C1A
    tBuffer             = GL_TEXTURE_BUFFER,               # 0x8C2A
    tCubeMapArray       = GL_TEXTURE_CUBE_MAP_ARRAY,       # 0x9009
    t2DMultisample      = GL_TEXTURE_2D_MULTISAMPLE,       # 0x9100
    t2DMultisampleArray = GL_TEXTURE_2D_MULTISAMPLE_ARRAY, # 0x9102

  TextureFormat* {.pure.} = enum
    Depth        = GL_DEPTH_COMPONENT # 0x1902
    Red          = GL_RED  # 0x1903
    RGB          = GL_RGB  # 0x1907
    RGBA         = GL_RGBA # 0x1908
    BGR          = GL_BGR  # 0x80E0
    BGRA         = GL_BGRA # 0x80E1
    RG           = GL_RG   # 0x8227
    DepthStencil = GL_DEPTH_STENCIL # 0x84F9

  PixelType* {.pure.} = enum
    Byte           = cGL_BYTE                       # 0x1400
    Ubyte          = GL_UNSIGNED_BYTE               # 0x1401
    Short          = cGL_SHORT                      # 0x1402
    Ushort         = GL_UNSIGNED_SHORT              # 0x1403
    Int            = cGL_INT                        # 0x1404
    Uint           = GL_UNSIGNED_INT                # 0x1405
    Float          = cGL_FLOAT                      # 0x1406

    Ubyte332       = GL_UNSIGNED_BYTE_3_3_2         # 0x8032
    Ushort4444     = GL_UNSIGNED_SHORT_4_4_4_4      # 0x8033
    Ushort5551     = GL_UNSIGNED_SHORT_5_5_5_1      # 0x8034
    Uint8888       = GL_UNSIGNED_INT_8_8_8_8        # 0x8035
    Uint1010102    = GL_UNSIGNED_INT_10_10_10_2     # 0x8036

    Ubyte233       = GL_UNSIGNED_BYTE_2_3_3_REV     # 0x8362
    Ushort565      = GL_UNSIGNED_SHORT_5_6_5        # 0x8363
    Ushort565rev   = GL_UNSIGNED_SHORT_5_6_5_REV    # 0x8364
    Ushort4444rev  = GL_UNSIGNED_SHORT_4_4_4_4_REV  # 0x8365
    Ushort1555rev  = GL_UNSIGNED_SHORT_1_5_5_5_REV  # 0x8366
    Uint8888rev    = GL_UNSIGNED_INT_8_8_8_8_REV    # 0x8367
    Uint2101010rev = GL_UNSIGNED_INT_2_10_10_10_REV # 0x8368

    Uint24_8       = GL_UNSIGNED_INT_24_8           # 0x84FA


  Texture* = object
    id*: GLuint
    target*: TextureTarget
    mipmap*: bool


proc generateMipmap*(t: var Texture) =
  t.mipmap = true
  glGenerateMipmap(ord t.target)


proc use*(t: Texture, unit: int) =
  glActiveTexture((GL_TEXTURE0 + unit).GLenum)
  glBindTexture(ord t.target, t.id)


proc image2d*(t: var Texture, data: string, w: int32, h: int32, format=TextureFormat.RGBA, pixeltype=PixelType.Ubyte, internalformat=GL_RGBA) =
  glTexImage2D(ord t.target, 0, internalformat.GLint, w, h, 0, ord format, ord pixeltype, if data == nil: nil else: cstring(data))


proc filter*(t: Texture, yes: bool) =
  if yes:
    if t.mipmap:
      glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
    else:
      glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    var aniso: float32
    glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, addr aniso);
    glTexParameterf(ord t.target, GL_TEXTURE_MAX_ANISOTROPY_EXT, aniso);
  else:
    glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

proc clamp*(t: Texture, border=false, border_color: array[4, float32] = [0'f32, 0, 0, 0]) =
  if border:
    glTexParameteri(ord t.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
    glTexParameteri(ord t.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)
  else:
    glTexParameteri(ord t.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(ord t.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

proc repeat*(t: Texture) =
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_S, GL_REPEAT)
  glTexParameteri(ord t.target, GL_TEXTURE_WRAP_T, GL_REPEAT)

proc newTexture*(target=TextureTarget.t2D): Texture =
  result = Texture(target: target)

  glGenTextures(1, addr result.id)
  glBindTexture(ord target, result.id)

proc emptyTexture*(t=TextureTarget.t2d): Texture = Texture(target: t, id: 0)
proc isEmpty*(t: Texture): bool = t.id.int == 0
