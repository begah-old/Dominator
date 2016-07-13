module isolated.math.ray;

import isolated.math;

struct Ray {
	private vec3 _origin;
	vec3 origin() @safe @property {return _origin;}

	private vec3 _direction;
	vec3 direction() @safe @property {return _direction;}

	this(vec3 origin, vec3 direction) {
		_origin = origin;
		_direction = direction;
	}

	bool intersects(vec3 point) { /* Check wether ray passes through point */
		float t1 = _direction.x != 0 ? (point.x - _origin.x) / _direction.x : float.nan;
		float t2 = _direction.y != 0 ? (point.y - _origin.y) / _direction.y : float.nan;
		float t3 = _direction.z != 0 ? (point.z - _origin.z) / _direction.z : float.nan;

		return false;
	}
}