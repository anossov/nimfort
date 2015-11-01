void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 posf = texture(gPosition, uv).rgb;
    vec4 _nm = texture(gNormalMetalness, uv);

    vec3 n = _nm.rgb;
    vec3 l = normalize(-lightDir);

    float shadow = 1.0;

    if (hasShadowmap) {
      float bias = max(0.002 * (1.0 - dot(n, l)), 0.0002);
      shadow = calcShadow(lightSpace * vec4(posf, 1.0), bias);
    }

    if (shadow == 0.0) {
        discard;
    }

    vec4 _ar = texture(gAlbedoRoughness, uv);
    float metalness = _nm.a;
    vec3  albedo    = _ar.rgb;
    float roughness = _ar.a;

    vec3 color = Shade_Cook_Torrance(l, posf, n, albedo, metalness, roughness);

    outColor = vec4(color * shadow, 1.0);
}
