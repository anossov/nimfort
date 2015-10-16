#version 400 core

layout(location=0) in vec3 pos;
layout(location=1) in vec2 uv;
layout(location=2) in vec3 normal;
layout(location=3) in vec3 tangent;
layout(location=4) in vec3 bitangent;

uniform float time;
uniform mat4 model;
uniform mat4 projection;
uniform mat4 view;

out vec2 uvf;
out vec4 posf;
out mat3 TBN;

void main() {
  uvf = uv;
  mat3 NM = mat3(transpose(inverse(model)));
  gl_Position = projection * view * model * vec4(pos, 1.0);
  posf = model * vec4(pos, 1.0);

  vec3 T = normalize(vec3(NM * tangent));
  vec3 B = normalize(vec3(NM * bitangent));
  vec3 N = normalize(vec3(NM * normal));
  TBN = mat3(T, B, N);
}