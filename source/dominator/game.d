module dominator.game;

import isolated.math;
import isolated.graphics.camera.perspective;
import isolated.graphics.camera.controller;
import isolated.graphics.utils.opengl;
import isolated.graphics.g3d.model;
import isolated.graphics.g3d.modelinstance;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;

import dominator.planet.planet;

import app : window;
import isolated.window;

class Game {
  Planet planet;
  PerspectiveCamera camera;
  CameraController controller;

  ModelType model;
  ModelInstance[4] _boxes;

  this() {
    camera = new PerspectiveCamera(window.screenDimension);
	camera.translate(vec3(0, 0, 0));
    controller = new CameraController(camera, window);

	window.addCallBack(&key);

    planet = new Planet(vec3(0), 5);

	model = Model.create(Mesh.Box(), planet.shader);

	_boxes[0] = new ModelInstance(model, vec3(0, 0, -2)); _boxes[0].scale = vec3(0.05f);
	_boxes[1] = new ModelInstance(model, vec3(0, 0, 2)); _boxes[1].scale = vec3(0.05f);
	_boxes[2] = new ModelInstance(model, vec3(2, 0, 0)); _boxes[2].scale = vec3(0.05f);
	_boxes[3] = new ModelInstance(model, vec3(-2, 0, 0)); _boxes[3].scale = vec3(0.05f);
  }

  void key(int key, int action, int mods) nothrow {
	if(action != GLFW_PRESS) return;

	if(key == GLFW_KEY_KP_0) camera.lookAt(_boxes[0].position);
	if(key == GLFW_KEY_KP_1) camera.lookAt(_boxes[1].position);
	if(key == GLFW_KEY_KP_2) camera.lookAt(_boxes[2].position);
	if(key == GLFW_KEY_KP_3) camera.lookAt(_boxes[3].position);
  }

  void update(float delta) {
	planet.update(camera, delta);
    camera.update(delta);
  }

  void render() {
	checkError();

	glEnable(GL_DEPTH_TEST);
    planet.render(camera);
	glEnable(GL_DEPTH_TEST);

	planet.shader.bind();
	/*planet.shader.uniform("uView", camera.viewMatrix);
	planet.shader.uniform("uProjection", camera.projectionMatrix);
	planet.shader.uniform("uTransform", mat4.identity);*/

	model.begin();

	planet.shader.uniform("Color", Color(255, 0, 0));
	_boxes[0].render();

	planet.shader.uniform("Color", Color(0, 0, 255));
	_boxes[1].render();

	planet.shader.uniform("Color", Color(0, 255, 0));
	_boxes[2].render();

	planet.shader.uniform("Color", Color(100, 100, 100));
	_boxes[3].render();

	model.end();

	glDisable(GL_DEPTH_TEST);

	checkError();
  }

  ~this() {
  }
}
