#version 330 core

uniform sampler2D sampler;

in vec2 textcoord;

out vec4 FragColor;

void main()
{
  FragColor = texture(sampler, textcoord);
}
