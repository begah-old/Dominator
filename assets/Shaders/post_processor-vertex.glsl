#version 330 core

layout (location = 0) in vec2 aposition;
layout (location = 1) in vec2 atextcoord;

out vec2 textcoord;

void main()
{
	gl_Position = vec4(aposition.x, aposition.y, 0.0f, 1.0f); 
	textcoord = atextcoord;
}