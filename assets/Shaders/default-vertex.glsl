#version 330 core

in vec3 aposition;

uniform mat4 uView;
uniform mat4 uProjection;
uniform mat4 uTransform;

void main()
{
	gl_Position = uProjection * uView * vec4(aposition, 1.0);
}
