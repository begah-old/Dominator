#version 330 core

uniform sampler2D sampler;
uniform vec4 textColor;

in vec2 textcoord;

out vec4 FragColor;

void main()
{
  vec4 color = vec4(textColor.xyz, texture(sampler, textcoord).r * textColor.w);
  FragColor = color;
}
