#version 330 core

layout (location = 0) in vec3 aposition;
layout (location = 1) in vec2 atextcoord;

uniform mat4 uTransform;

out vec2 textcoord;

void main()
{
	gl_Position = uTransform * vec4(aposition, 1.0);
	textcoord = atextcoord;
}
