#version 400 core

in vec2 uvf;
out vec4 outColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;

uniform sampler2DShadow shadowMap;

uniform vec3 eye;
uniform vec4 light;
uniform mat4 lightspace;
uniform bool hasShadowmap;

uniform float radius;


float calcShadow(vec4 fpLS, float bias) {
    vec3 posfLP = fpLS.xyz / fpLS.w;
    posfLP = posfLP * 0.5 + 0.5;
    posfLP.z = posfLP.z - bias;

    
    // float shadow = 0.0;
    // vec2 texelSize = 1.0 / textureSize(shadowMap, 0);
    // for(int x = -1; x <= 1; ++x)
    // {
    //   for(int y = -1; y <= 1; ++y)
    //   {
    //       vec3 tc = vec3(posfLP.xy + vec2(x, y) * texelSize, posfLP.z);
    //       shadow += texture(shadowMap, tc);
    //   }
    // }
    // return shadow / 9.0;
    return texture(shadowMap, posfLP);
}


void main() {
    vec3 n = texture(gNormal, uvf).rgb;

    if (n == vec3(0.0, 0.0, 0.0)) {
      discard;
    }

    vec4 AS = texture(gAlbedoSpec, uvf);
    vec3 color = AS.rgb;
    float spec = AS.a;
    vec3 posf = texture(gPosition, uvf).rgb;

    vec3 l = normalize(light.xyz - posf * light.w);
    vec3 v = normalize(eye - posf);
    vec3 h = normalize(l + v);
 
    float shadow = 1.0;

    if (hasShadowmap) {
      float bias = max(0.003 * (1.0 - dot(n, l)), 0.0002);
      shadow = calcShadow(lightspace * vec4(posf, 1.0), bias);  
    }

    float lighting = max(dot(n, l), 0.0) + pow(max(dot(n, h), 0.0), 64.0) * spec;

    float ld = length(light.xyz - posf);
    float attenuation = clamp(1.0 - ld * ld / (radius * radius), 0.0, 1.0);
    attenuation = attenuation * attenuation;

    outColor = vec4(color, 1.0) * max(lighting * shadow * attenuation, 0.0);
    
   // outColor = vec4(1.0) * lighting * shadow * attenuation;
   // outColor = outColor + vec4(light.w * 0.01, 0.0, 0.0, 1.0);
}