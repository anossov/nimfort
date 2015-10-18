#version 400 core

in vec2 uvf;
out vec4 outColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;

uniform vec3 eye;
uniform vec3 light;
uniform float radius;
uniform vec3 lightColor;

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

    float ld = length(light.xyz - posf);
    float attenuation = clamp(1.0 - ld * ld / (radius * radius), 0.0, 1.0);
    attenuation = attenuation * attenuation;    
  
    outColor = vec4(color * lightColor * max(lighting * attenuation, 0.0), 1.0);
}