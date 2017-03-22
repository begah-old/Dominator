#version 330 core

layout (location = 0) in vec3 aposition;
layout (location = 1) in vec4 acolor;

uniform mat4 uTransform;

out vec4 color;

void main()
{
	gl_Position = uTransform * vec4(aposition, 1.0);
	color = acolor;
}
