#version 330 core
out float outColor;

uniform sampler2D input;
uniform vec2 invBufferSize;

void main() {
  vec2 uv = gl_FragCoord.xy * invBufferSize;

  float result = 0.0;
  for (int x = -2; x < 2; ++x) {
    for (int y = -2; y < 2; ++y) {
      vec2 offset = vec2(float(x), float(y)) * invBufferSize;
      result += texture(input, uv + offset).r;
    }
  }
  outColor = result / (4.0 * 4.0);
}
