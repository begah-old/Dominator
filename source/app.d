module app;

import std.stdio;
import std.exception;
import std.conv;
import std.string;

import isolated.math;
import isolated.math.boundingbox;
import isolated.window;
import isolated.utils.logger;
import isolated.graphics.utils.opengl;
import isolated.graphics.shader;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;
import isolated.graphics.g3d.model;
import isolated.graphics.g3d.scene3d;
import isolated.graphics.camera.perspective;
import isolated.graphics.g3d.modelinstance;
import isolated.graphics.camera.controller;
import isolated.graphics.texture;

import dominator.game;

Window window;

int main() {
	window = new Window("Test application");
	window.title = "DS";
	window.show();

	Game game = new Game();

	core.memory.GC.collect();

	while(window.shouldClose() == false) {
        glViewport(0, 0, window.screenDimension.x, window.screenDimension.y);
    	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

		glEnable(GL_DEPTH_TEST);

		game.update();
		game.render();

		checkError();
		window.refresh();

		core.memory.GC.collect();
	}

	ModelManager.purge();
	TextureManager.purge();

	window.close();

	return 0;
}
