#version 400 core

in vec2 uvf;
out vec4 outColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;

uniform vec3 lightColor;
uniform vec2 invBufferSize;


void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec4 AS = texture(gAlbedoSpec, uv);

    outColor = vec4(AS.rgb * lightColor, 1.0);
}