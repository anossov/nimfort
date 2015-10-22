#version 400 core

in vec2 uv;

layout (location = 0) out vec4 outColor;


uniform sampler2D hdr;
uniform float exposure;

const float A = 0.15;
const float B = 0.50;
const float C = 0.10;
const float D = 0.20;
const float E = 0.02;
const float F = 0.30;
const float W = 11.2;

vec3 Uncharted2Tonemap(vec3 x)
{
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}


void main() {
	vec3 color = texture(hdr, uv).rgb;

	float E = exposure;

	color = Uncharted2Tonemap(E * color);
	vec3 scale = 1.0 / Uncharted2Tonemap(vec3(W));
	color = color * scale;

	//color = color / (color + vec3(1.0));

    outColor = vec4(color, 1.0);
}
