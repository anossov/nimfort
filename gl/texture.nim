import opengl
import nimPNG

type
  TextureTarget* {.pure.} = enum
    t1D                 = GL_TEXTURE_1D,                   # 0x0DE0
    t2D                 = GL_TEXTURE_2D,                   # 0x0DE1
    t3D                 = GL_TEXTURE_3D,                   # 0x806F
    tRectangle          = GL_TEXTURE_RECTANGLE,            # 0x84F5
    tCubeMap            = GL_TEXTURE_CUBE_MAP,             # 0x8513    
    t1DArray            = GL_TEXTURE_1D_ARRAY,             # 0x8C18
    t2DArray            = GL_TEXTURE_2D_ARRAY,             # 0x8C1A
    tBUffer             = GL_TEXTURE_BUFFER,               # 0x8C2A    
    tCubeMapArray       = GL_TEXTURE_CUBE_MAP_ARRAY,       # 0x9009
    t2DMultisample      = GL_TEXTURE_2D_MULTISAMPLE,       # 0x9100
    t2DMultisampleArray = GL_TEXTURE_2D_MULTISAMPLE_ARRAY, # 0x9102

  Texture* = object
    id: GLuint

proc use*(t: Texture) = 
  glBindTexture(ord TextureTarget.t2D, t.id)

proc newTexture*(path: string): Texture = 
  result = Texture()
  
  let image = loadPNG32(path)
  if image == nil:
    stderr.writeln("Failed to load file: " & path)
    return
  let t2d: GLenum = ord TextureTarget.t2D

  glGenTextures(1, addr result.id)
  glBindTexture(t2d, result.id)
  
  glTexImage2D(t2d, 0, GL_SRGB, image.width.GLsizei, image.height.GLsizei, 0, GL_RGBA, GL_UNSIGNED_BYTE, cstring(image.data));
  glGenerateMipmap(t2d);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
