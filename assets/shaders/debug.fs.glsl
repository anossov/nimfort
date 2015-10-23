#version 410 compatibility

uniform sampler2D t;
uniform bool alpha;

in vec2 texcoord;
out vec4 color;

void main()
{
  vec4 c = texture(t, texcoord);
  if (alpha) {
      color = vec4(c.aaa, 1.0);
  } else {
      color = vec4(c.rgb, 1.0);
  }
}
