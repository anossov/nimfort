uniform samplerCube cubemap;

void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 posf = texture(gPosition, uv).rgb;
    vec4 _nm = texture(gNormalMetalness, uv);

    vec3 n = _nm.rgb;
    if (n == vec3(0.0)) {
        discard;
    }

    vec3 v = normalize(eye - posf);

    vec4 _ar = texture(gAlbedoRoughness, uv);
    float metalness = _nm.a;
    vec3  albedo    = _ar.rgb;
    float roughness = _ar.a;

    vec3 r = reflect(-v, n);

    vec3 f0 = mix(vec3(0.03), albedo, metalness);
    albedo = albedo * (1.0 - metalness);

    float VdotN = clamp(dot(v, n), 0.0, 1.0);
    vec3 F = F_Schlick(f0, VdotN);

    vec3 env = textureLod(cubemap, r, 3 + roughness * 6).rgb;
    vec3 spec = F * env;
    vec3 diff = albedo * (1.0 - F) * textureLod(cubemap, n, 9).rgb;
    vec3 color = diff + spec;


    outColor = vec4(lightColor * color, 1.0);
}
