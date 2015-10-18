#version 400 core

in vec2 uvf;
out vec4 outColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;

uniform sampler2DShadow shadowMap;

uniform vec3 eye;
uniform vec3 light;
uniform vec3 lightDir;
uniform vec3 lightColor;
uniform mat4 lightspace;
uniform bool hasShadowmap;
uniform float cosSpotAngle;
uniform float cosSpotFalloff;

float calcShadow(vec4 fpLS, float bias) {
    vec3 posfLP = fpLS.xyz / fpLS.w;
    posfLP = posfLP * 0.5 + 0.5;
    posfLP.z = posfLP.z - bias;

    return texture(shadowMap, posfLP);
}

void main() {
    vec3 n = texture(gNormal, uvf).rgb;
    vec4 AS = texture(gAlbedoSpec, uvf);
    vec3 posf = texture(gPosition, uvf).rgb;

    vec3 color = AS.rgb;
    float spec = AS.a;

    vec3 l = normalize(light.xyz - posf);
    vec3 v = normalize(eye - posf);
    vec3 h = normalize(l + v);
 
    float lighting = max(dot(n, l), 0.0) + pow(max(dot(n, h), 0.0), 64.0) * spec;

    float theta = dot(l, normalize(-lightDir));
    float penumbra = cosSpotAngle - cosSpotFalloff;
    float intensity = clamp((theta - cosSpotFalloff) / penumbra, 0.0, 1.0);

    float shadow = 1.0;

    if (hasShadowmap) {
      float bias = max(0.02 * (1.0 - dot(n, l)), 0.0002);
      shadow = calcShadow(lightspace * vec4(posf, 1.0), bias);  
    }
  
    outColor = vec4(color * lightColor * max(lighting * intensity * shadow, 0.0), 1.0);
}