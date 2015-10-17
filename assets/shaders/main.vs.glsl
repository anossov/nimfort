#version 400 core

layout(location=0) in vec3 pos;

uniform mat4 transform;

out vec2 uvf;

void main() {
  gl_Position = transform * vec4(pos, 1.0);
  uvf = (gl_Position.xy/gl_Position.w + 1.0) / 2.0;
  gl_Position.z = 0.0;
}