import logging
import opengl
import gl/texture

type
  FramebufferTarget* {.pure.} = enum
    Read = GL_READ_FRAMEBUFFER # 0x8CA8
    Draw = GL_DRAW_FRAMEBUFFER # 0x8CA9
    Both = GL_FRAMEBUFFER      # 0x8D40

  AttachmentPoint* {.pure.} = enum
    DepthStencil = GL_DEPTH_STENCIL_ATTACHMENT # 0x821A
    Color        = GL_COLOR_ATTACHMENT0        # 0x8CE0
    Depth        = GL_DEPTH_ATTACHMENT         # 0x8D00
    Stencil      = GL_STENCIL_ATTACHMENT       # 0x8D20

  Framebuffer* = object
    id*: GLuint
    target*: FramebufferTarget
    depth: bool
    stencil: bool
    colors: GLsizei


proc attach*(fb: var Framebuffer, t: Texture, depth=false, stencil=false, level=0, tt=ord TextureTarget.Texture2d) =
  var ap: GLenum

  if depth and stencil:
    ap = ord AttachmentPoint.DepthStencil
    fb.depth = true
    fb.stencil = true
  elif depth:
    ap = ord AttachmentPoint.Depth
    fb.depth = true
  elif stencil:
    ap = ord AttachmentPoint.Stencil
    fb.stencil = true
  else:
    ap = ((ord AttachmentPoint.Color) + fb.colors).GLenum
    fb.colors += 1

  glFramebufferTexture2D(ord fb.target, ap, tt.GLenum, t.id, level.GLint)

  if fb.colors > 0:
    var bufs = newSeq[GLenum](fb.colors)
    for i in 0..(fb.colors-1):
      bufs[i] = ((ord AttachmentPoint.Color) + i).GLenum
    glDrawBuffers(fb.colors, addr bufs[0])


# TODO: RBO object
proc attachDepthStencilRBO*(fb: Framebuffer, w: int32, h: int32) =
  var rbo: GLuint
  glGenRenderbuffers(1, addr rbo)
  glBindRenderbuffer(GL_RENDERBUFFER, rbo)
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, w, h)
  glFramebufferRenderbuffer(ord fb.target, ord AttachmentPoint.DepthStencil, GL_RENDERBUFFER, rbo)


proc check*(fb: Framebuffer): string =
  let status = glCheckFramebufferStatus(ord fb.target)
  case status:
  of GL_FRAMEBUFFER_COMPLETE: "OK"
  of GL_FRAMEBUFFER_UNDEFINED: "Undefined"
  of GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: "Incomplete attachment"
  of GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: "Missing attachment"
  of GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER: "Incomplete draw buffer"
  of GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER: "Incomplete read buffer"
  of GL_FRAMEBUFFER_UNSUPPORTED: "Unsupported formats"
  of GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE: "Invalid multisampling"
  of GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS: "Invalid layering"
  of 0: "Unknown error"
  else: "should not happen"


proc use*(fb: var Framebuffer, t=FramebufferTarget.Both) =
  glBindFramebuffer(ord t, fb.id)
  fb.target =t


proc useDefaultFramebuffer*(t=FramebufferTarget.Both) =
  glBindFramebuffer(ord t, 0)


proc newFramebuffer*(t=FramebufferTarget.Both): Framebuffer =
  result = Framebuffer(target: t)

  glGenFramebuffers(1, addr result.id)
  result.use(t)
