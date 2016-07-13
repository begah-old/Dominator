module isolated.graphics.camera.camera;

import isolated.math;

class Camera
{
	protected {
		const float NEAR_PLANE = 0.1f;
		const float FAR_PLANE = 1000;

		vec3 translation;
		float pitch = 0, yaw = 0; // pitch ( around X axis ), yaw ( around Y axis )

		bool dirty = true;
	}

	public {
		vec2i viewport;
		mat4 viewMatrix;
		mat4 projectionMatrix;
	}

	pure nothrow @safe @nogc :

	this(vec2i viewport, vec3 position) {
		this.translation = position;
		this.viewport = viewport;

		yaw = std.math.PI_2;
	}

	void lookAt(vec3 target) {

	}

	void translate(float x, float y, float z) {
		translate(vec3(x, y, z));
	}

	void translate(vec3 pos) nothrow {
		this.translation = this.translation + pos;
		dirty = true;
	}

	void setTranslation(float x, float y, float z) {
		setTranslation(vec3(x, y, z));
	}

	void setTranslation(vec3 pos) nothrow {
		this.translation = pos;
		dirty = true;
	}

	@property vec3 position() {
		return this.translation;
	}

	void rotate(float yaw, float pitch) {
		this.pitch += pitch;
		this.yaw += yaw;
		dirty = true;
	}

	void update() {

	}

	float getYaw() {
		return yaw;
	}
	float getPitch() {
		return pitch;
	}
}
