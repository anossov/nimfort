#version 400 core

in vec2 uv;

layout (location = 0) out vec4 outColor;

uniform sampler2D color;
uniform sampler2D bloom;


void main() {
	vec3 c = texture(color, uv).rgb;
	vec3 b = texture(bloom, uv).rgb;

  outColor = vec4(c + b, 1.0);
}
