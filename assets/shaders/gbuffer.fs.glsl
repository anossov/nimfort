#version 400 core

layout (location = 0) out vec4 gPosition;
layout (location = 1) out vec4 gNormalMetalness;
layout (location = 2) out vec4 gAlbedoRoughness;

in vec2 uvf;
in vec4 posf;
in mat3 TBN;
out vec4 outColor;

uniform sampler2D albedo;
uniform sampler2D normal;
uniform sampler2D roughness;
uniform sampler2D metalness;
uniform sampler2D emission;
uniform float emissionIntensity;

void main()
{
    gPosition.rgb = vec3(posf);
    gPosition.a = texture(emission, uvf).r * emissionIntensity;
    vec3 n = texture(normal, uvf).rgb;
    if (n != vec3(0.0)) {
        n = normalize(n * 2.0 - 1.0);
        gNormalMetalness.rgb = normalize(TBN * n);
    } else {
        gNormalMetalness.rgb = TBN[2];
    }
    gNormalMetalness.a = texture(metalness, uvf).r;

    gAlbedoRoughness.rgb = texture(albedo, uvf).rgb;
    gAlbedoRoughness.a = texture(roughness, uvf).r;
}
