#version 400 core

layout (location = 0) out vec3 gPosition;
layout (location = 1) out vec3 gNormal;
layout (location = 2) out vec4 gAlbedoSpec;

in vec2 uvf;
in vec4 posf;
in mat3 TBN;
out vec4 outColor;

uniform sampler2D tex;
uniform sampler2D normalmap;
uniform sampler2D specularmap;

void main()
{    
    gPosition = vec3(posf);

    vec3 n = texture(normalmap, uvf).rgb;
    if (n != vec3(0.0)) {
        n = normalize(n * 2.0 - 1.0);   
        gNormal = normalize(TBN * n);
    } else {
        gNormal = TBN[2];
    }


    gAlbedoSpec.rgb = texture(tex, uvf).rgb;
    gAlbedoSpec.a = texture(specularmap, uvf).r;
} 