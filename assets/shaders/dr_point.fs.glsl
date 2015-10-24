uniform float radius;

void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 posf = texture(gPosition, uv).rgb;
    vec4 _nm = texture(gNormalMetalness, uv);

    vec3 n = _nm.rgb;
    vec3 l = normalize(lightPos.xyz - posf);

    vec4 _ar = texture(gAlbedoRoughness, uv);
    float metalness = _nm.a;
    vec3  albedo    = _ar.rgb;
    float roughness = _ar.a;

    vec3 color = Shade_Cook_Torrance(l, posf, n, albedo, metalness, roughness);

    float ld = length(lightPos.xyz - posf);
    float dr = ld / radius;
    float falloff_num = clamp(1.0 - dr * dr * dr * dr, 0.0, 1.0);
    float attenuation = falloff_num * falloff_num / (ld * ld + 1);
    attenuation = attenuation * attenuation;

    outColor = vec4(color * attenuation, 1.0);
}
