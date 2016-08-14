module dominator.game;

import isolated.math;
import isolated.graphics.camera.perspective;
import isolated.graphics.camera.controller;
import dominator.planet.planet;

import app : window;

class Game {
  Planet planet;
  PerspectiveCamera camera;

  this() {
    camera = new PerspectiveCamera(window.screenDimension);
    new CameraController(camera, window);

    planet = new Planet(vec3(0), 3);
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
