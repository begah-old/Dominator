#version 330 core

uniform sampler2D sceneSampler;
uniform sampler2D guiSampler;
uniform sampler2D guiDepthSampler;

in vec2 textcoord;

out vec4 FragColor;

void main()
{
	vec4 guiColor = texture(guiSampler, textcoord);
	vec4 sceneColor = texture(sceneSampler, textcoord);
	float depth = texture(guiDepthSampler, textcoord).r;
	
	FragColor = sceneColor * depth + guiColor * (1 - depth);
}
