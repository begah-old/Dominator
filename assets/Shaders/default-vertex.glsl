#version 330 core

layout (location = 0) in vec3 aposition;
layout (location = 1) in vec3 anormal;
layout (location = 2) in vec4 acolor;

uniform mat4 uView;
uniform mat4 uProjection;
uniform mat4 uTransform;

out vec4 Color;

void main()
{
	gl_Position = uProjection * uView * uTransform * vec4(aposition, 1.0);
	Color = acolor;
}
