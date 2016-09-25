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
import isolated.utils.timer;

import dominator.game;

Window window;

int main() {
	window = new Window("Dominator");
	window.show();

	Game game = new Game();

	core.memory.GC.collect();

	Timer timer = Timer();
	long lastFrameTime;
	long updateAndRenderTime;
	long initialSetupTime;

	while(window.shouldClose() == false) {
		timer = timer.reset();

        glViewport(0, 0, window.screenDimension.x, window.screenDimension.y);
    	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

		initialSetupTime = timer.elapsedTime;

		checkError();

		game.update(lastFrameTime);
		game.render();

		updateAndRenderTime = timer.elapsedTime;

		checkError();
		window.refresh();

		core.memory.GC.collect();

		lastFrameTime = timer.elapsedTime;

		//Logger.info("Total time : " ~ lastFrameTime.to!string ~ " while it took " ~ updateAndRenderTime.to!string ~ " time to update and render and " ~ initialSetupTime.to!string ~ " to set up next frame");
	}

	ModelManager.purge();
	TextureManager.purge();

	window.close();
	readln();

	return 0;
}
