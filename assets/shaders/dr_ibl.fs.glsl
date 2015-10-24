uniform samplerCube cubemap;

void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 posf = texture(gPosition, uv).rgb;
    vec4 _nm = texture(gNormalMetalness, uv);

    vec3 n = _nm.rgb;
    vec3 v = normalize(eye - posf);

    vec4 _ar = texture(gAlbedoRoughness, uv);
    float metalness = _nm.a;
    vec3  albedo    = _ar.rgb;
    float roughness = _ar.a;

    vec3 r = reflect(v, n);

    vec3 f0 = mix(vec3(0.03), albedo, metalness);

    float VdotN = clamp(dot(v, n), 0.0, 1.0);
    vec3 F = F_Schlick(f0, VdotN);

    vec3 env = textureLod(cubemap, r, 4 + roughness * 5).rgb;
    vec3 spec = F * env;
    vec3 diff = albedo * (1.0 - metalness) / PI;
    vec3 color = diff + spec;

    outColor = vec4(color, 1.0);
}
