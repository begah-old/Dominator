module isolated.graphics.camera.orthographic;

import isolated.graphics.camera.camera;
import isolated.math;

class OrthographicCamera : Camera
{
	nothrow @safe @nogc :

	this(vec2i viewport) {
		this(viewport, vec3(0, 0, 0));
	}
	
	this(vec2i viewport, vec3 position) {
		super(viewport, position);
	}

	override @nogc void update(float delta) {
		if(_dirty) {
			projectionMatrix.make_identity();

			viewMatrix.make_identity();
			viewMatrix.translate(-_translation);
			viewMatrix.rotatez(-(_yaw - std.math.PI_2)); // Because it is needed that at the start, the camera points toward negative z
			viewMatrix.rotatex(-_pitch);
			
			_dirty = false;
		}
	}
}

