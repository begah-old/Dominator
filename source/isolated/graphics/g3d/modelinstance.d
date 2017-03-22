module isolated.graphics.g3d.modelinstance;

import isolated.graphics.g3d.model;
import isolated.graphics.vertexattribute;
import isolated.graphics.mesh;
import isolated.graphics.utils.opengl;
import isolated.math;
import isolated.utils.logger;

class ModelInstance
{
	public {
		Model model;
		
		vec3 position;
		vec3 scale;
		vec3 rotation;
	}

	private {
		mat4 transformation;
		bool isDirty = true;

		struct SpecificVertices {
			size_t index;
			VertexAttribute attribute;
		}

		SpecificVertices[] specificVertices; // Specific information that changes some vertex info
	}

	this(Model model, vec3 position = vec3(0)) in {assert(model !is null);}
	body {
		this.position = position;

		this.model = model;
		
		this.scale = vec3(1);
		this.rotation = vec3(0);
	}

	void changeVertexInfo(VertexAttribute.Usage usage, bool dynamic, float[] data...) {
		size_t index = size_t.max;
		foreach(i, va; model.mesh.attributes) {
			if(va.usage == usage) {
				index = i;
				break;
			}
		}
		if (index == size_t.max) return;

		SpecificVertices sp = SpecificVertices(index, new VertexAttribute(model.mesh.attributes[index]));

		if(data.length != 0) {
			import std.string : join;
			import std.range : repeat;

			assert(data.length % sp.attribute.vertexSize == 0, "Data needs to be a multiple of " ~ to!string(sp.attribute.vertexSize));

			if(data.length == sp.attribute.vertexCount * sp.attribute.vertexSize)
				sp.attribute.data = data.dup;
			else
				sp.attribute.data = join(data.repeat(sp.attribute.data.length / data.length));
		}

		if(dynamic) sp.attribute.toggleDynamic;
		sp.attribute.generate();

		specificVertices ~= sp;
	}

	void vertexInfoSet(VertexAttribute.Usage usage, int start, int end, float[] data...) {
		foreach(sv; specificVertices) {
			if(sv.attribute.usage == usage) {
				sv.attribute.replace(start, end, data);
				sv.attribute.refresh();
				break;
			}
		}
	}

	void setTransformation(mat4 transform) {
		transformation = transform;
		isDirty = false;
	}

	void render() {
		if(isDirty) {
			isDirty = false;
			
			transformation = calculateTransformation(position, rotation, scale);
		}

		if(specificVertices.length != 0) {
			glBindVertexArray(model.mesh.vao);
			
			foreach(sp; specificVertices) {
				glBindBuffer(GL_ARRAY_BUFFER, sp.attribute.vbo);
				glEnableVertexAttribArray(cast(GLint)sp.attribute.vaoIndex);
				glVertexAttribPointer(cast(GLint)sp.attribute.vaoIndex, cast(GLint)sp.attribute.vertexSize, GL_FLOAT, GL_FALSE, 0, null);
			}
		}
		
		model.render(transformation);

		if(specificVertices.length != 0) {
			glBindVertexArray(model.mesh.vao);

			foreach(sp; specificVertices) {
				glBindBuffer(GL_ARRAY_BUFFER, model.mesh.attributes[sp.index].vbo);
				glEnableVertexAttribArray(cast(GLint)model.mesh.attributes[sp.index].vaoIndex);
				glVertexAttribPointer(cast(GLint)model.mesh.attributes[sp.index].vaoIndex, cast(GLint)model.mesh.attributes[sp.index].vertexSize, GL_FLOAT, GL_FALSE, 0, null);
			}
		}
	}
	
	void translate(float x, float y, float z) {
		translate(vec3(x, y, z));
	}
	
	void translate(vec3 vector) {
		position += vector;
		isDirty = true;
	}
	
	void setTranslation(float x, float y, float z) {
		setTranslation(vec3(x, y, z));
	}
	
	void setTranslation(vec3 vector) {
		position = vector;
		isDirty = true;
	}
}

