#version 410 compatibility

uniform sampler2D t;

in vec2 texcoord;
out vec4 color;

void main()
{
	color = vec4(texture(t, texcoord).rgb, 1.0);
}
