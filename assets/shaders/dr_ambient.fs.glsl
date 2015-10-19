void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec4 AS = texture(gAlbedoRoughness, uv);

    outColor = vec4(AS.rgb * lightColor, 1.0);
}