module isolated.graphics.camera.controller;

import isolated.graphics.camera.camera;
import isolated.window;
import isolated.math;

class CameraController
{
	Camera camera;
	Window window;

	float speed = 0.05;

	this(Camera camera, Window window)
	{
		this.camera = camera;
		this.window = window;
		window.addCallBack(&keyCallback);
	}

	void keyCallback(int key, int action, int mods) {
		if(action) {
			float yaw = -camera.yaw();
			vec2 direction = vec2(cos(yaw), sin(yaw));

			switch(key) {
				case GLFW_KEY_W:
					vec2 translation = direction * speed;
					camera.translate(translation.x, 0, translation.y);
					break;
				case GLFW_KEY_S:
					vec2 translation = -direction * speed;
					camera.translate(translation.x, 0, translation.y);
					break;
				case GLFW_KEY_A:
					vec2 translation = vec2(direction.y, -direction.x) * speed;
					camera.translate(translation.x, 0, translation.y);
					break;
				case GLFW_KEY_D:
					vec2 translation = vec2(-direction.y, direction.x) * speed;
					camera.translate(translation.x, 0, translation.y);
					break;
				case GLFW_KEY_SPACE:
					camera.translate(0, speed, 0);
					break;
				case GLFW_KEY_LEFT_SHIFT:
					camera.translate(0, -speed, 0);
					break;
				case GLFW_KEY_LEFT:
					camera.rotate(0.05, 0);
					break;
				case GLFW_KEY_RIGHT:
					camera.rotate(-0.05, 0);
					break;
				case GLFW_KEY_UP:
					camera.rotate(0, 0.05);
					break;
				case GLFW_KEY_DOWN:
					camera.rotate(0, -0.05);
					break;
				default: break;
			}
		}
	}
}
