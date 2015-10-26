#version 330 core
in vec2 TexCoords;
out vec4 color;
uniform sampler2D text;
uniform vec4 textColor;

void main()
{
    vec4 sampled = textColor;
    sampled.a *= texture(text, TexCoords).r;
    color = sampled;
}
