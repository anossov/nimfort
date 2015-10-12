#version 400 core

layout(location=0) in vec3 pos;
layout(location=1) in vec2 uv;
layout(location=2) in vec3 normal;

uniform float time;
uniform mat4 model;
uniform mat4 projection;
uniform mat4 view;

out vec2 uvf;
out vec3 n;
out vec4 posf;

void main() {
  uvf = uv;
  n = normalize(mat3(transpose(inverse(model))) * normal);
  gl_Position = projection * view * model * vec4(pos, 1.0);
  posf = model * vec4(pos, 1.0);
}