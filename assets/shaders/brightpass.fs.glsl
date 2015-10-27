#version 400 core

in vec2 uv;

layout (location = 0) out vec4 outColor;

uniform sampler2D t;
uniform float threshold;

void main() {
	vec3 color = texture(t, uv).rgb;
  float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  outColor = vec4(color, 1.0) * float(luma > threshold);

  outColor = vec4(color * smoothstep(2.0, threshold, luma), 1.0);
}
