module isolated.graphics.camera.orthographic;

import isolated.graphics.camera.camera;
import isolated.math;

class OrthographicCamera : Camera
{
	this(vec2i viewport) {
		this(viewport, vec3(0, 0, 0));
	}
	
	this(vec2i viewport, vec3 position) {
		super(viewport, position);
	}

	override void calculate() {
		if(_dirty) {
			projectionMatrix.make_identity();

			viewMatrix.make_identity();
			viewMatrix.translate(-_translation);
			viewMatrix.rotatez(-(_yaw - PI_2)); // Because it is needed that at the start, the camera points toward negative z
			viewMatrix.rotatex(-_pitch);
			
			_dirty = false;
		}
	}
}

