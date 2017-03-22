module isolated.math.ray;

import isolated.math;

struct Ray {
	nothrow @safe @nogc :

	private vec3 _origin;
	vec3 origin() @property {return _origin;}

	private vec3 _direction;
	vec3 direction() @property {return _direction;}

	this(vec3 origin, vec3 direction) {
		_origin = origin;
		_direction = direction;
	}

	/// Check wether ray passes through point
	bool intersects(vec3 point) {
		float t1 = _direction.x != 0 ? (point.x - _origin.x) / _direction.x : float.nan;
		float t2 = _direction.y != 0 ? (point.y - _origin.y) / _direction.y : float.nan;
		float t3 = _direction.z != 0 ? (point.z - _origin.z) / _direction.z : float.nan;

		return t1 != float.nan && almost_equal(t1, t2, 0.0001) && almost_equal(t2, t3, 0.0001);
	}

	/// Check if ray intersects with triangle
	bool intersects(vec3 v0, vec3 v1, vec3 v2) { // Algorithm found on site : http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
		vec3 e1 = v1 - v0;
		vec3 e2 = v2 - v0;
		vec3 h = cross(_direction, e2);
		float a = dot(e1, h);

		if (a > -0.00001 && a < 0.00001)
			return false;

		float f = 1 / a;
		vec3 s = _origin - v0;
		float u = f * dot(s, h);

		if (u < 0.0 || u > 1.0)
			return false;

		vec3 q = cross(s, e1);
		float v = f * dot(_direction, q);

		if (v < 0.0 || u + v > 1.0)
			return false;

		float t = f * dot(e2, q);

		if(t > 0.00001)
			return true;	
		else
			return false;
	}

	char[100] toString() @property @trusted {
		import core.stdc.stdio : sprintf;
		char[100] str;
		sprintf(str.ptr, "Ray origin : [%f, %f, %f], direction : [%f, %f, %f]\n", _origin.x, _origin.y, _origin.z, _direction.x, _direction.y, _direction.z);
		return str;
	}
}