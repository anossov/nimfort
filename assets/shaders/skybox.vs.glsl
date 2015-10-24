#version 330 core
layout (location = 0) in vec4 position;

smooth out vec3 uv;

uniform mat4 projection;
uniform mat4 view;

void main()
{
    mat4 inverseProjection = inverse(projection);
    mat3 inverseview = transpose(mat3(view));
    vec3 unprojected = (inverseProjection * position).xyz;
    uv = -inverseview * unprojected;
    gl_Position = position;
    gl_Position.z = 1.0;
}
