#version 400 core

out vec4 outColor;

uniform vec4 color;


void main()
{
    outColor = vec4(color.rgb * color.a, color.a);
}
