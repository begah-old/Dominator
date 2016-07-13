module isolated.graphics.mesh;

import isolated.graphics.vertexattribute;
import isolated.graphics.utils.opengl;
import isolated.graphics.shader;
import isolated.math;

class Mesh
{
	VertexAttribute[] attributes;

	GLuint vao;

nothrow @trusted :

	VertexAttribute add(VertexAttribute attribute) {
		attributes ~= attribute;
		return attribute;
	}

	VertexAttribute get(VertexAttribute.Usage usage) {
		foreach(attribute; attributes) {
			if(attribute.usage == usage)
				return attribute;
		}
		return new VertexAttribute(usage, 0); // TODO: throw instead
	}

	void generate(Shader shader) {
		foreach(attribute; attributes) {
			attribute.generate();
		}

		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		foreach(attribute; attributes) {
			foreach(usage; shader.vertexAttributes) {
				if(attribute.usage == usage) {
					glBindBuffer(GL_ARRAY_BUFFER, attribute.vbo);
					glEnableVertexAttribArray(usage.location);
					glVertexAttribPointer(usage.location, attribute.vertexSize, GL_FLOAT, GL_FALSE, 0, null);
					break;
				}
			}
		}

		glBindVertexArray(0);
	}

	@property vertexCount() {
		if(attributes.length == 0)
			return 0;
		return attributes[0].vertexCount;
	}

	bool isGenerated() {
		return vao != GLuint.init;
	}

	~this() {
		if(isGenerated())
			glDeleteVertexArrays(1, &vao);
	}

	/* Two dimensional objects */
	static Mesh Quad(vec2 pos1, vec2 pos2, vec2 pos3, vec2 pos4, vec2 textcoord1, vec2 textcoord2, vec2 textcoord3, vec2 textcoord4, vec4 color1, vec4 color2, vec4 color3, vec4 color4, float depth = 0, int attributes = VertexAttribute.Usage.Position) {
		Mesh mesh = new Mesh();

		if(attributes & VertexAttribute.Usage.Position)
			mesh.add(new VertexAttribute(VertexAttribute.Usage.Position, 3).add([pos1.x, pos1.y, depth, pos2.x, pos2.y, depth, pos3.x, pos3.y, depth, pos1.x, pos1.y, depth, pos3.x, pos3.y, depth, pos4.x, pos4.y, depth]));
		if(attributes & VertexAttribute.Usage.ColorPacked)
			mesh.add(new VertexAttribute(VertexAttribute.Usage.ColorPacked, 4).add([color1.x, color1.y, color1.z, color1.w, color2.x, color2.y, color2.z, color2.w, color3.x, color3.y, color3.z, color3.w, color1.x, color1.y, color1.z, color1.w, color3.x, color3.y, color3.z, color3.w, color4.x, color4.y, color4.z, color4.w]));
		if(attributes & VertexAttribute.Usage.TextureCoordinates)
			mesh.add(new VertexAttribute(VertexAttribute.Usage.TextureCoordinates, 2).add([textcoord1.x, textcoord1.y, textcoord2.x, textcoord2.y, textcoord3.x, textcoord3.y, textcoord1.x, textcoord1.y, textcoord3.x, textcoord3.y, textcoord4.x, textcoord4.y]));
		if(attributes & VertexAttribute.Usage.Normal)
			mesh.add(new VertexAttribute(VertexAttribute.Usage.Normal, 3).add([0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1]));

		return mesh;
	}

	static Mesh Square(float x, float y, float width, float height, float depth = 0, int attributes = VertexAttribute.Usage.Position) {
		return Quad(vec2(x, y), vec2(x + width, y), vec2(x + width, y + height), vec2(x, y + height),
			vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1), vec4(1), vec4(1), vec4(1), vec4(1), depth, attributes);
	}

	/* position is the position of the left down corner */
	static Mesh Square(vec2 position, vec2 dimension, float depth = 0, int attributes = VertexAttribute.Usage.Position) {
		return Square(position.x, position.y, dimension.x, dimension.y, depth, attributes);
	}
}
