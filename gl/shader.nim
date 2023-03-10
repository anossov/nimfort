import opengl
import tables
import logging

import engine/vector

type
  ShaderType* {.pure.} = enum
    Fragment       = GL_FRAGMENT_SHADER,        # 0x8B30
    Vertex         = GL_VERTEX_SHADER,          # 0x8B31
    Geometry       = GL_GEOMETRY_SHADER,        # 0x8DD9
    TessEvaluation = GL_TESS_EVALUATION_SHADER, # 0x8E87
    TessControl    = GL_TESS_CONTROL_SHADER,    # 0x8E88
    Compute        = GL_COMPUTE_SHADER,         # 0x91B9

  ShaderInfo {.pure.} = enum
    Type          = GL_SHADER_TYPE,          # 0x8B4F
    DeleteStatus  = GL_DELETE_STATUS,        # 0x8B80
    CompileStatus = GL_COMPILE_STATUS,       # 0x8B81
    LogLength     = GL_INFO_LOG_LENGTH,      # 0x8B84
    SourceLength  = GL_SHADER_SOURCE_LENGTH, # 0x8B88

  ProgramInfo {.pure.} = enum
    DeleteStatus       = GL_DELETE_STATUS,               # 0x8B80
    LinkStatus         = GL_LINK_STATUS,                 # 0x8B82
    ValdateStatus      = GL_VALIDATE_STATUS,             # 0x8B83
    LogLength          = GL_INFO_LOG_LENGTH,             # 0x8B84
    Shaders            = GL_ATTACHED_SHADERS,            # 0x8B85
    Uniforms           = GL_ACTIVE_UNIFORMS,             # 0x8B86
    UniformMaxLength   = GL_ACTIVE_UNIFORM_MAX_LENGTH,   # 0x8B87
    Attributes         = GL_ACTIVE_ATTRIBUTES,           # 0x8B89
    AttributeMaxLength = GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, # 0x8B8A

  Shader = object
    id: GLuint
    src: cstringArray
    shaderType: ShaderType

  Program* = ref object
    id: GLuint

    fs: Shader
    vs: Shader
    gs: Shader

    uniforms: Table[string, Uniform]

  Uniform = object
    location: GLint


proc getInfo(s: Shader, param: ShaderInfo): GLint =
  glGetShaderiv(s.id, ord param, addr result)


proc getInfo(p: Program, param: ProgramInfo): GLint =
  glGetProgramiv(p.id, ord param, addr result)


proc infoLog(s: Shader): cstring =
  var ll = s.getInfo(ShaderInfo.LogLength)
  result = cast[cstring](alloc(ll))
  glGetShaderInfoLog(s.id, ll, addr ll, result)
  discard


proc infoLog(p: Program): cstring =
  var ll = p.getInfo(ProgramInfo.LogLength)
  result = cast[cstring](alloc(ll))
  glGetProgramInfoLog(p.id, ll, addr ll, result)


proc delete(s: Shader) =
  glDeleteShader(s.id)


proc createShader*(t: ShaderType, src: string): Shader =
  result = Shader(shaderType: t)
  result.src = allocCStringArray([src])
  result.id = glCreateShader(ord t)

  glShaderSource(result.id, 1, result.src, nil)
  glCompileShader(result.id)

  if result.getInfo(ShaderInfo.CompileStatus) == GL_FALSE:
    fatal(result.infoLog())


proc use*(p: Program) {.inline.} =
  glUseProgram(p.id)

proc findUniform*(p: Program, name: string): Uniform =
  result = Uniform()
  result.location = glGetUniformLocation(p.id, name)
  if result.location == -1:
    debug("Could not find uniform: " & name)

proc getUniform*(p: var Program, name: string): Uniform =
  if p.uniforms.hasKey(name):
    return p.uniforms[name]
  p.uniforms[name] = p.findUniform(name)
  return p.uniforms[name]

proc createProgram*(vs: string, fs: string, gs: string): Program =
  result = Program(
    id: glCreateProgram(),
    uniforms: initTable[string, Uniform](),
    vs: createShader(ShaderType.Vertex, vs),
    fs: createShader(ShaderType.Fragment, fs),
    gs: Shader(shaderType: ShaderType.Geometry)
  )

  glAttachShader(result.id, result.fs.id)
  glAttachShader(result.id, result.vs.id)

  if gs != nil:
    result.gs = createShader(ShaderType.Geometry, gs)
    glAttachShader(result.id, result.gs.id)

  glLinkProgram(result.id)

  if result.getInfo(ProgramInfo.LinkStatus) == GL_FALSE:
    fatal(result.infoLog())

proc bindFragDataLocation*(p: Program, num: GLuint, name: string) {.inline.} =
  glBindFragDataLocation(p.id, num, name)


proc set*(u: Uniform, b1: bool) =
  if u.location == -1: return
  glUniform1i(u.location, b1.int32)

proc set*(u: Uniform, i1: int32) =
  if u.location == -1: return
  glUniform1i(u.location, i1)

proc set*(u: Uniform, f1: float32) =
  if u.location == -1: return
  glUniform1f(u.location, f1)

proc set*(u: Uniform; f1, f2: float32) =
  if u.location == -1: return
  glUniform2f(u.location, f1, f2)

proc set*(u: Uniform; f1, f2, f3: float32) =
  if u.location == -1: return
  glUniform3f(u.location, f1, f2, f3)

proc set*(u: Uniform; f1, f2, f3, f4: float32) =
  if u.location == -1: return
  glUniform4f(u.location, f1, f2, f3, f4)

proc set*(u: Uniform, v: vec2) =
  if u.location == -1: return
  var v = v
  glUniform2fv(u.location, 1, v.value_ptr)

proc set*(u: Uniform, v: vec3) =
  if u.location == -1: return
  var v = v
  glUniform3fv(u.location, 1, v.value_ptr)

proc set*(u: Uniform, v: vec4) =
  if u.location == -1: return
  var v = v
  glUniform4fv(u.location, 1, v.value_ptr)

proc set*(u: Uniform, m: mat4) =
  if u.location == -1: return
  var m = m
  glUniformMatrix4fv(u.location, 1, GL_FALSE.GLboolean, m.value_ptr)


proc delete*(p: Program) =
  p.use()

  glDetachShader(p.id, p.vs.id)
  glDetachShader(p.id, p.fs.id)
  glDeleteProgram(p.id)
  glDeleteShader(p.vs.id)
  glDeleteShader(p.fs.id)
  deallocCStringArray(p.fs.src)
  deallocCStringArray(p.vs.src)
