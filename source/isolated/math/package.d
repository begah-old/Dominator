module isolated.math;

public import isolated.math.ray;
public import isolated.math.icosphere;
public import isolated.math.boundingbox;

public import gl3n.linalg;
public import gl3n.plane;
public import gl3n.frustum;
public import gl3n.interpolate;
public import gl3n.aabb;
public import gl3n.math;
public import gl3n.util;

public import std.math : PI_2;

mat4 calculateTransformation(vec3 position, vec3 rotation, vec3 scale) {
	mat4 mat = mat4.identity;
	mat.set_translation(position.x, position.y, position.z);
	mat.rotatex(rotation.x).rotatey(rotation.y).rotatez(rotation.z);
	mat.set_scale(scale.x, scale.y, scale.z);
	return mat;
}

bool pointInSquare(V, V2, V3)(V point, V2 origin, V3 size) {
	return point.x >= origin.x && point.x <= origin.x + size.x && point.y >= origin.y && point.y <= origin.y + size.y;
}