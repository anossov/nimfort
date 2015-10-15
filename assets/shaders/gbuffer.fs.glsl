#version 400 core

layout (location = 0) out vec3 gPosition;
layout (location = 1) out vec3 gNormal;
layout (location = 2) out vec4 gAlbedoSpec;

in vec2 uvf;
in vec3 n;
in vec4 posf;
out vec4 outColor;

uniform sampler2D tex;

void main()
{    
    gPosition = vec3(posf);
    gNormal = normalize(n);
    gAlbedoSpec.rgb = texture(tex, vec2(uvf.s, 1.0 - uvf.t)).rgb;
    gAlbedoSpec.a = 1.0;
} 