#version 330 core
in vec2 TexCoords;
out vec4 color;
uniform sampler2D text;
uniform vec3 textColor;

void main()
{    
    vec4 sampled = vec4(textColor, texture(text, TexCoords).r);
    color = sampled;
}  