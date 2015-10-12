#version 400 core

in vec2 uvf;
in vec3 n;
in vec4 posf;
out vec4 outColor;

uniform sampler2D tex;
uniform vec3 eye;


void main() {
    vec3 lp = vec3(2.0, 1.5, -1.0);
    vec3 ld = normalize(lp - vec3(posf));
    float diff = max(dot(normalize(n), ld), 0.1);

    vec3 vd = normalize(eye - vec3(posf));
    vec3 hwd = normalize(ld + vd);

    float spec = pow(max(dot(n, hwd), 0.0), 128);

    outColor = (diff + spec) * texture(tex, vec2(uvf.s, 1.0 - uvf.t));
    outColor.a = 1.0;
}