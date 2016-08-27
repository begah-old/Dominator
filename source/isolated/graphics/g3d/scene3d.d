module isolated.graphics.g3d.scene3d;

import isolated.graphics.mesh;
import isolated.graphics.camera.perspective;

import isolated.graphics.g3d.model;
import isolated.graphics.g3d.modelinstance;
import isolated.graphics.shader;
import isolated.graphics.utils.opengl;
import isolated.utils.logger;
import std.conv;
import isolated.graphics.texture;

class Scene3d
{
	PerspectiveCamera camera;
	ModelInstance[][ModelType] instances;

	Shader shader;

	this(PerspectiveCamera camera) {
		this(camera, new Shader("Shaders/default"));
	}

	this(PerspectiveCamera camera, Shader shader) {
		this.camera = camera;
		this.shader = shader;
	}

	void add(ModelInstance[] instances...) {
		foreach(ref instance; instances) {
			this.instances[instance.model] ~= instance;
		}
	}

	void render() {
		checkError();
		shader.bind();

		shader.uniform("uView", camera.viewMatrix);
		shader.uniform("uProjection", camera.projectionMatrix);

		foreach(ref model, ref instances; this.instances) {
			model.begin();
			foreach(instance; instances) {
				instance.render();
			}
			model.end();
		}

		shader.unbind();
		checkError();
	}

	~this() {

	}
}
