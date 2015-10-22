#version 410 compatibility

layout(location=0) in vec3 pos;
layout(location=1) in vec2 atexcoord;

out vec2 texcoord;

void main()
{
	texcoord = atexcoord;
	gl_Position = vec4(pos, 1.0);
}
