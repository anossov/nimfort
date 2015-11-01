uniform float cosSpotAngle;
uniform float cosSpotFalloff;


void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 posf = getPosition();
    vec4 _nm = texture(gNormalMetalness, uv);

    vec3 n = _nm.rgb;
    vec3 l = normalize(lightPos.xyz - posf);

    vec4 _ar = texture(gAlbedoRoughness, uv);
    float metalness = _nm.a;
    vec3  albedo    = _ar.rgb;
    float roughness = _ar.a;

    vec3 color = Shade_Cook_Torrance(l, posf, n, albedo, metalness, roughness);

    float theta = dot(l, normalize(-lightDir));
    float penumbra = cosSpotAngle - cosSpotFalloff;
    float intensity = clamp((theta - cosSpotFalloff) / penumbra, 0.0, 1.0);

    float shadow = 1.0;

    if (hasShadowmap) {
      float bias = max(0.02 * (1.0 - dot(n, l)), 0.0002);
      shadow = calcShadow(lightSpace * vec4(posf, 1.0), bias);
    }

    outColor = vec4(color * shadow * intensity, 1.0);
}
