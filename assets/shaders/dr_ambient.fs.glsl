uniform vec3 colors[6];
uniform sampler2D AO;

void main() {
    vec2 uv = gl_FragCoord.xy * invBufferSize;
    vec3 a = texture(gAlbedoRoughness, uv).rgb;
    vec3 n = texture(gNormalMetalness, uv).rgb;
    float ao = texture(AO, uv).r;

    float nox = dot(n, vec3(1.0, 0.0, 0.0));
    float noy = dot(n, vec3(0.0, 1.0, 0.0));
    float noz = dot(n, vec3(0.0, 0.0, 1.0));

    vec3 ex = nox * nox * mix(colors[1], colors[0], float(nox > 0));
    vec3 ey = noy * noy * mix(colors[3], colors[2], float(noy > 0));
    vec3 ez = noz * noz * mix(colors[5], colors[4], float(noz > 0));

    vec3 E = ex + ey + ez;

    outColor = vec4(E * a * ao, 1.0);
}
