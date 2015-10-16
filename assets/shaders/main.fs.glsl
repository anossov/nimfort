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
  // Ashikhmin-Shirley brdf
    
    vec3 Rd = texture(gAlbedoSpec, uvf).rgb;
    vec3 n = texture(gNormal, uvf).rgb;
    vec3 posf = texture(gPosition, uvf).rgb;

    if (n == vec3(0.0, 0.0, 0.0)) {
      outColor = vec4(0.0, 0.4, 0.5, 1.0);
      return;
    }

    vec3 l = normalize(light);
    vec3 v = normalize(eye - posf);
    vec3 h = normalize(l + v);
 
    vec3 epsilon = vec3(1.0, 0.0, 0.0);
    vec3 tangent = normalize(cross(n, epsilon));
    vec3 bitangent = normalize(cross(n, tangent));
 

    float VdotN = dot(v, n);
    float LdotN = dot(l, n);
    float HdotN = dot(h, n);
    float HdotL = dot(h, l);
    float HdotT = dot(h, tangent);
    float HdotB = dot(h, bitangent);
 
    vec3 Rs = vec3(0.3, 0.3, 0.3);
 
    float Nu = 200;
    float Nv = 32;
 
    
    vec3 Pd = (28.0 * Rd) / ( 23.0 * 3.14159 );
    Pd *= (1.0 - Rs);
    Pd *= (1.0 - pow(1.0 - (LdotN / 2.0), 5.0));
    Pd *= (1.0 - pow(1.0 - (VdotN / 2.0), 5.0));
 

    float ps_num_exp = Nu * HdotT * HdotT + Nv * HdotB * HdotB;
    ps_num_exp /= (1.0 - HdotN * HdotN);
 
    float Ps_num = sqrt((Nu + 1) * (Nv + 1));
    Ps_num *= pow( HdotN, ps_num_exp );
 
    float Ps_den = 8.0 * 3.14159 * HdotL;
    Ps_den *= max( LdotN, VdotN );
 
    vec3 Ps = Rs * (Ps_num / Ps_den);
    Ps *= (Rs + (1.0 - Rs) * pow(1.0 - HdotL, 5.0));
 
    vec4 amb = vec4(0.04 * Rd, 1.0);

    float bias = max(0.0008 * (1.0 - dot(n, l)), 0.0002);
    float shadow = calcShadow(lightspace * vec4(posf, 1.0), bias);
    outColor = max(amb, shadow * vec4(2.0 * (Pd + Ps), 1.0));
}