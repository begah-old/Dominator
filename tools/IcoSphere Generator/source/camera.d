module camera;

import gl3n.linalg;
import gl3n.math;

class Camera
{
	protected {
		const float NEAR_PLANE = 0.1f;
		const float FAR_PLANE = 1000;
		const float FOV = 70;
		
		const float PI_2 = PI / 2.0f;

		vec3 _translation;
		float _pitch = 0, _yaw = 0; // pitch ( look up and down ), yaw ( rotate around )

		bool _dirty = true;

		bool _isMoving = false;
		vec3 _targetedTranslation;
		vec2 _targetedRotation;

		vec2 _targetSpeed;
	}

	public {
		vec2i viewport;
		mat4 viewMatrix;
		mat4 projectionMatrix;
	}

	nothrow @safe @nogc :

	this(vec2i viewport, vec3 position) {
		this._translation = position;
		this.viewport = viewport;

		_yaw = PI_2;
	}

	void translate(float x, float y, float z) {
		translate(vec3(x, y, z));
	}

	void translate(vec3 pos) nothrow {
		this._translation = this._translation + pos;
		_dirty = true;
	}

	void setTranslation(float x, float y, float z) {
		setTranslation(vec3(x, y, z));
	}

	void setTranslation(vec3 pos) nothrow {
		this._translation = pos;
		_dirty = true;
	}

	@property vec3 position() {
		return this._translation;
	}

	void rotate(float yaw, float pitch) {
		this._pitch += pitch;
		this._yaw += yaw;
		_dirty = true;
	}

	/// Make the camera rotate to look at point
	void lookAt(vec3 target) {
		target -= _translation;

		_yaw = asin(-target.z / target.xz.magnitude);

		if(_yaw >= 0 && target.x < 0) _yaw += 2 * (PI_2 - _yaw);
		else if(_yaw < 0) {
			if(target.x < 0) _yaw -= 2 * (PI_2 + _yaw) ;

			_yaw += 2 * PI;
		}

		target.normalize();

		_pitch = asin(target.y);

		_dirty = true;
	}

	// Update the camera matrix and position. Delta time is in milli-seconds
	void update() {
		if(_dirty) {
			projectionMatrix = mat4.perspective(viewport.x, viewport.y, FOV, abs(NEAR_PLANE), abs(FAR_PLANE));

			viewMatrix.make_identity();
			viewMatrix.translate(-position);
			viewMatrix.rotatey(-(yaw - PI_2)); // Because it is needed that at the start, the camera points toward negative z
			viewMatrix.rotatex(-pitch);

			_dirty = false;
		}
	}

	float yaw() {
		return _yaw;
	}
	float pitch() {
		return _pitch;
	}
}