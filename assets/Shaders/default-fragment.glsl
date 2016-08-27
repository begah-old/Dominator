#version 330 core

in vec2 texturecoord;

uniform sampler2D sampler;
uniform vec4 Color;

out vec4 FragColor;

void main()
{
  FragColor = Color;//texture(sampler, texturecoord);
}
