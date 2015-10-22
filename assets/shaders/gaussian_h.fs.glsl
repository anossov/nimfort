#version 400 core

in vec2 uv;

layout (location = 0) out vec4 outColor;

uniform sampler2D t;

uniform vec2 pixelSize;

const float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );
const float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );

void main() {
    vec3 result = texture(t, uv).rgb * weight[0];

    for(int i = 1; i < 3; ++i) {
        vec2 to = vec2(offset[i] * pixelSize.x, 0.0);
        result += texture(t, uv + to).rgb * weight[i];
        result += texture(t, uv - to).rgb * weight[i];
    }

    outColor = vec4(result, 1.0);
}
