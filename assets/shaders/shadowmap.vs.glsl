#version 400 core

layout(location=0) in vec3 pos;

uniform mat4 model;
uniform mat4 lightspace;

void main() {
  gl_Position = lightspace * model * vec4(pos, 1.0);
}