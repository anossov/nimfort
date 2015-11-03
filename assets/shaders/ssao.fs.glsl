#version 330 core

out float outColor;

uniform sampler2D depth;
uniform sampler2D normals;
uniform sampler2D noise;

uniform vec3 kernel[64];

uniform int noiseSize;
uniform int kernelSize;
uniform float radius;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 normalToView;
uniform mat4 invPV;
uniform vec2 invBufferSize;

vec4 getPosition(vec2 uv) {
  float zw = texture(depth, uv).r * 2 - 1;
  vec4 H = vec4(uv.x * 2 - 1, (uv.y) * 2 - 1, zw, 1);
  vec4 D = invPV * H;
  return D / D.w;
}

void main()
{
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 pW = getPosition(uv).xyz;
    vec3 nW = texture(normals, uv).rgb;

    vec3 pV = (view * vec4(pW, 1.0)).xyz;
    vec3 nV = (normalToView * vec4(nW, 1.0)).xyz;

    vec3 randomVec = texture(noise, uv / invBufferSize / noiseSize).xyz;

    vec3 tangent = normalize(randomVec - nV * dot(randomVec, nV));
    vec3 bitangent = cross(nV, tangent);
    mat3 TBN = mat3(tangent, bitangent, nV);

    float occlusion = 0.0;
    for(int i = 0; i < kernelSize; ++i)
    {
        vec3 sample = TBN * kernel[i];
        sample = pV + sample * radius;

        vec4 offset = vec4(sample, 1.0);
        offset = projection * offset;
        offset.xyz /= offset.w;
        offset.xyz = offset.xyz * 0.5 + 0.5;

        vec4 pSample = view * getPosition(offset.xy);
        float sampleDepth = pSample.z;

        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(pV.z - sampleDepth));
        occlusion += (sampleDepth >= sample.z ? 1.0 : 0.0) * rangeCheck;
    }

    occlusion = 1.0 - (occlusion / kernelSize);

    outColor = occlusion;
}
