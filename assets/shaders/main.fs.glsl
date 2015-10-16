#version 400 core

in vec2 uvf;
out vec4 outColor;

uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;

uniform sampler2DShadow shadowMap;

uniform vec3 eye;
uniform vec3 light;
uniform mat4 lightspace;


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
      outColor = vec4(0.0, 0.4, 0.5, 1.0);
      return;
    }

    vec4 AS = texture(gAlbedoSpec, uvf);
    vec3 color = AS.rgb;
    vec3 spec = vec3(AS.a);
    vec3 posf = texture(gPosition, uvf).rgb;

    vec3 ambient = 0.1 * color;

    vec3 l = normalize(light);
    vec3 v = normalize(eye - posf);
    vec3 h = normalize(l + v);
 
    float bias = max(0.003 * (1.0 - dot(n, l)), 0.0002);
    float shadow = calcShadow(lightspace * vec4(posf, 1.0), bias);

    vec3 diffuse = max(dot(n, l), 0.0) * color;
    vec3 specular = pow(max(dot(n, h), 0.0), 64.0) * spec;

    outColor = vec4(ambient + (diffuse + specular) * shadow, 1.0f);
}