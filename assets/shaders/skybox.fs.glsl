#version 330 core

in vec3 uv;
out vec4 color;

uniform samplerCube skybox;
uniform vec3 intensity;

void main()
{
    color = vec4(texture(skybox, uv).rgb * intensity, 1.0);
}
