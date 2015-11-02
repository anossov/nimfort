#version 400 core

out vec4 outColor;

uniform sampler2D gNormalMetalness;
uniform sampler2D gAlbedoRoughness;
uniform sampler2D gDepth;

uniform sampler2DShadow shadowMap;

uniform vec3 eye;
uniform vec3 lightPos;
uniform vec3 lightDir;
uniform vec3 lightColor;
uniform mat4 lightSpace;
uniform bool hasShadowmap;
uniform vec2 invBufferSize;
uniform mat4 invPV;

const float PI = 3.1415926536;


float calcShadow(vec4 fpLS, float bias) {
    vec3 posfLP = fpLS.xyz / fpLS.w;
    posfLP = posfLP * 0.5 + 0.5;
    posfLP.z = posfLP.z - bias;
    if (posfLP.x > 1.0 || posfLP.y > 1.0) {
    	return 1.0;
    }
    if (posfLP.x < 0.0 || posfLP.y < 0.0) {
    	return 1.0;
    }

    return texture(shadowMap, posfLP);
}

vec3 getPosition() {
  vec2 uv = gl_FragCoord.xy * invBufferSize;
  float zw = texture(gDepth, uv).r * 2 - 1;
  vec4 H = vec4(uv.x * 2 - 1, (uv.y) * 2 - 1, zw, 1);
  vec4 D = invPV * H;
  return D.xyz / D.w;
}
