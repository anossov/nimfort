#version 400 core

layout(location=0) in vec3 pos;
layout(location=1) in vec2 uv;
layout(location=2) in vec3 normal;

out vec2 uvf;

void main() {
  uvf = uv;
  gl_Position = vec4(pos, 1.0);
}