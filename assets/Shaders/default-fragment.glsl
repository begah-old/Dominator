#version 330 core

in vec4 Color;

out vec4 FragColor;

uniform vec4 ColorControl;

void main()
{
  FragColor = Color * ColorControl;
}
