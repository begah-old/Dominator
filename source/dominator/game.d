module familysurvival.game;

import isolated.math;
import isolated.graphics.camera.perspective;
import isolated.graphics.camera.controller;
import familysurvival.planet.planet;

import app : window;

class Game {
  Planet planet;
  PerspectiveCamera camera;

  this() {
    camera = new PerspectiveCamera(window.screenDimension);
	camera.rotate(0, PI_2);
    new CameraController(camera, window);

    planet = new Planet(vec3(0));
  }

  void update() {
    camera.update();
  }

  void render() {
    planet.render(camera);
  }

  ~this() {
  }
}
