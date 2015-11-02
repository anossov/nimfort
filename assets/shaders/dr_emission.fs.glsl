#version 400 core

in vec2 uvf;
in vec4 posf;

out vec4 outColor;

uniform sampler2D albedo;
uniform sampler2D emission;

uniform float emissionIntensity;

void main() {
    float emission = texture(emission, uvf).r;
    vec3 albedo = texture(albedo, uvf).rgb;
    outColor = vec4(albedo * emission * emissionIntensity, 1.0) * clamp(emission, 0.0, 1.0);
}
