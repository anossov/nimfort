import opengl
import logging

type
  BufferTarget* {.pure.} = enum
    btUnitialized = 0
    Array             = GL_ARRAY_BUFFER,              # 0x8892
    ElementArray      = GL_ELEMENT_ARRAY_BUFFER,      # 0x8893
    PixelPack         = GL_PIXEL_PACK_BUFFER,         # 0x88EB
    PixelUnpack       = GL_PIXEL_UNPACK_BUFFER,       # 0x88EC
    Uniform           = GL_UNIFORM_BUFFER,            # 0x8A11
    Texture           = GL_TEXTURE_BUFFER,            # 0x8C2A
    TransformFeedback = GL_TRANSFORM_FEEDBACK_BUFFER, # 0x8C8E
    CopyRead          = GL_COPY_READ_BUFFER,          # 0x8F36
    CopyWrite         = GL_COPY_WRITE_BUFFER,         # 0x8F37
    Draw              = GL_DRAW_INDIRECT_BUFFER,      # 0x8F3F
    ShaderStorage     = GL_SHADER_STORAGE_BUFFER,     # 0x90D2
    Dispatch          = GL_DISPATCH_INDIRECT_BUFFER,  # 0x90EE
    Query             = GL_QUERY_BUFFER,              # 0x9192
    Counter           = GL_ATOMIC_COUNTER_BUFFER,     # 0x92C0

  BufferUsage* {.pure.} = enum
    StreamDraw  = GL_STREAM_DRAW,  # 0x88E0
    StreamRead  = GL_STREAM_READ,  # 0x88E1
    StreamCopy  = GL_STREAM_COPY,  # 0x88E2
    StaticDraw  = GL_STATIC_DRAW,  # 0x88E4
    StaticRead  = GL_STATIC_READ,  # 0x88E5
    StaticCopy  = GL_STATIC_COPY,  # 0x88E6
    DynamicDraw = GL_DYNAMIC_DRAW, # 0x88E8
    DynamicRead = GL_DYNAMIC_READ, # 0x88E9
    DynamicCopy = GL_DYNAMIC_COPY, # 0x88EA

  Buffer* = object
    id: GLuint
    target: BufferTarget

  VAO* = object
    id: GLuint


var vaoState: int


proc use*(v: VAO) =
  if v.id.int != vaoState:
    glBindVertexArray(v.id)
    vaoState = v.id.int

proc use*(b: Buffer) =
  glBindBuffer(ord b.target, b.id)

proc delete*(b: VAO) =
  var id = b.id
  glDeleteVertexArrays(1, addr id)

proc delete*(b: Buffer) =
  var id = b.id

  glDeleteBuffers(1, addr id)

proc createVAO*(): VAO =
  result = VAO()
  glGenVertexArrays(1, addr result.id)
  glBindVertexArray(result.id)

proc initialized*(o: VAO): bool = o.id != 0

proc emptyBuffer*(target: BufferTarget): Buffer = Buffer(target: target)


proc createBuffer*[T](data: var openarray[T], target: BufferTarget): Buffer =
  let u: GLenum = ord BufferUsage.StaticDraw

  result = Buffer(target: target)

  glGenBuffers(1, addr result.id)
  result.use()

  let size = len(data) * sizeof(data[0])

  if size > 0:
    glBufferData(ord result.target, size.GLsizeiptr, addr data[0], u)


proc createVBO*[T](data: var openarray[T]): Buffer =
  result = createBuffer(data, BufferTarget.Array)

proc createEBO*[T](data: var openarray[T]): Buffer =
  result = createBuffer(data, BufferTarget.ElementArray)
