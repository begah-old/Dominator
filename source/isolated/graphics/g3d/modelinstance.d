module isolated.graphics.g3d.modelinstance;

import isolated.graphics.g3d.model;
import isolated.math;
import isolated.utils.logger;

class ModelInstance
{
	public {
		ModelType model;
		
		vec3 position;
		vec3 scale;
		vec3 rotation;
	}

	private {
		mat4 transformation;
		bool isDirty = true;
	}

	this(ModelType model, vec3 position = vec3(0)) in {assert(model.initialized);}
	body {
		this.position = position;

		this.model = model;
		
		this.scale = vec3(1);
		this.rotation = vec3(0);
	}

	void render() {
		if(isDirty) {
			isDirty = false;
			
			transformation.make_identity();
			transformation.set_translation(position.x, position.y, position.z);
			transformation.rotatex(rotation.x).rotatey(rotation.y).rotatez(rotation.z);
			transformation.set_scale(scale.x, scale.y, scale.z);
		}
		
		model.render(transformation);
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

