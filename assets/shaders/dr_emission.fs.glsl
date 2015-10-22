#version 400 core

out vec4 outColor;

uniform sampler2D gPosition;
uniform sampler2D gAlbedoRoughness;
uniform vec2 invBufferSize;

void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec4 pos_em = texture(gPosition, uv);
    vec3 pos = pos_em.rgb;
    float emission = pos_em.a;
    vec3 albedo = texture(gAlbedoRoughness, uv).rgb;
    outColor = vec4(albedo * emission, 1.0) * clamp(emission, 0.0, 1.0);
}
