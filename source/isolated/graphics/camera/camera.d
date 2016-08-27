module isolated.graphics.camera.camera;

import isolated.math;

import isolated.utils.logger;

class Camera
{
	protected {
		const float NEAR_PLANE = 0.1f;
		const float FAR_PLANE = 1000;

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

		_yaw = std.math.PI_2;
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

	/// Move smoothly the camera to a new position to look at a target. Allows to pass time wished for translation animation and rotation animation
	void moveToLookAt(vec3 targetPosition, vec3 targetLookAt, float translationTime = 2, float rotationTime = 4) {
		vec2 tempRot = vec2(_pitch, _yaw);
		_targetedTranslation = _translation;
		_translation = targetPosition;

		lookAt(targetLookAt);

		_translation = _targetedTranslation;

		_targetedTranslation = targetPosition;
		_targetedRotation = vec2(_pitch, _yaw);
		_pitch = tempRot.x; _yaw = tempRot.y;

		_targetSpeed = vec2((_targetedTranslation - _translation).magnitude / translationTime / 1000.0f, (_targetedRotation - vec2(_pitch, _yaw)).magnitude / rotationTime / 1000.0f);

		_isMoving = true;
	}

	// Update the camera matrix and position. Delta time is in milli-seconds
	void update(float delta) {
		if(_isMoving) {
			vec3 direction = _targetedTranslation - _translation;
			float travelSpeed = _targetSpeed.x * delta;

			if(travelSpeed >= direction.magnitude) {
				_translation = _targetedTranslation;
				_targetSpeed.x = 0;

				_dirty = true;
			} else if(_targetSpeed.x != 0) {
				_translation += travelSpeed * direction.normalized;
			
				_dirty = true;
			}

			vec2 rotDirection = _targetedRotation - vec2(_pitch, _yaw);
			travelSpeed = _targetSpeed.y * delta;

			if(abs(rotDirection.x) <= travelSpeed) {
				_pitch = _targetedRotation.x;
				rotDirection.x = 0;
			} else {
				if(rotDirection.x < 0) _pitch -= travelSpeed;
				else _pitch += travelSpeed;
			}

			if(abs(rotDirection.y) <= travelSpeed) {
				_yaw = _targetedRotation.y;
				rotDirection.y = 0;
			} else {
				if(rotDirection.y < 0) _yaw -= travelSpeed;
				else _yaw += travelSpeed;
			}

			if(rotDirection.x == 0 && rotDirection.y == 0)
				_targetSpeed.y = 0;

			if(_targetSpeed.x == 0 && _targetSpeed.y == 0)
				_isMoving = false;

			_dirty = true;
		}
	}

	float yaw() {
		return _yaw;
	}
	float pitch() {
		return _pitch;
	}
}
