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
    Red  = GL_RED  # 0x1903
    RGB  = GL_RGB  # 0x1907
    RGBA = GL_RGBA # 0x1908
    BGR  = GL_BGR  # 0x80E0
    BGRA = GL_BGRA # 0x80E1
    RG   = GL_RG   # 0x8227

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

  Texture* = object
    id: GLuint
    target: TextureTarget


proc use*(t: Texture) = 
  glBindTexture(ord t.target, t.id)

proc image2d*(t: Texture, data: string, w: int32, h: int32, mipmap=true, format=TextureFormat.RGBA, pixeltype=PixelType.Ubyte) = 
  glTexImage2D(ord t.target, 0, GL_SRGB, w, h, 0, ord format, ord pixeltype, cstring(data))

  if mipmap:
      glGenerateMipmap(ord t.target)

proc filter*(t: Texture, yes: bool) = 
  if yes:
    glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
    glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  else:
    glTexParameteri(ord t.target, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(ord t.target, GL_TEXTURE_MAG_FILTER, GL_NEAREST)


proc newTexture*(target=TextureTarget.t2D): Texture = 
  result = Texture(target: target)
  
  glGenTextures(1, addr result.id)
  glBindTexture(ord target, result.id)