module isolated.math.boundingbox;

import isolated.math;
import std.conv;

@safe @nogc nothrow:

interface BoundingBox {
	BoundingBox fromPoints(vec3[] points...);
	BoundingBox fromPoints(float[] points...);

	void expand(float[3] points);

	bool intersects(BoundingBox box);
	bool intersects(vec3 point);
}

class Sphere : BoundingBox {
	private {
		vec3 totalPoints;
		int numberOfPoints;
	}

	vec3 center;
	float squaredRaduis, raduis;

	Sphere fromPoints(vec3[] points...) {
		if(points.length == 0) {
			return null;
		}
		
		Sphere sphere = new Sphere();

		sphere.center = points[0];

		foreach(v; points[1..$]) {
			sphere.expand(v.vector);
		}
		
		return sphere;
	}

	Sphere fromPoints(float[] points...)  in { assert(points.length % 3 == 0, "Number of points should be divisible by 3"); } 
	body {
		if(points.length == 0) {
			return null;
		}
		
		Sphere sphere = new Sphere();

		sphere.center = vec3(points[0 .. 3]);
		
		for(int i = 1; i < points.length / 3; i++) {
			sphere.expand(to!(float[3])(points[i * 3 .. (i + 1) * 3]));
		}
		
		return sphere;
	}

	void expand(float[3] points) {
		float lengthSquare = lengthSquareFrom(points);
		
		if(lengthSquare > squaredRaduis) {
			totalPoints += vec3(points);
			numberOfPoints++;
			vec3 newcenter = totalPoints / numberOfPoints;

			float length = sqrt(lengthSquare);
			vec3 v = newcenter - center;
			
			float aX = center.x + v.x / length * raduis;
			float aY = center.y + v.y / length * raduis;
			float aZ = center.z + v.z / length * raduis;

			aX -= 2 * (aX - center.x); // Furthest point of old circle from new center
			aY -= 2 * (aY - center.y);
			aZ -= 2 * (aZ - center.z);

			center = newcenter;

			lengthSquare = lengthSquareFrom(points); // Length of new point from new center
			float lengthSquare2 = lengthSquareFrom([aX, aY, aZ]); // Length of point on old circle from new center

			squaredRaduis = max(lengthSquare, lengthSquare2);
			raduis = sqrt(squaredRaduis);
		}
	}

	private float lengthSquareFrom(float[3] points) {
		return (points[0] - center.x) * (points[0] - center.x) + (points[1] - center.y) * (points[1] - center.y) + (points[2] - center.z) * (points[2] - center.z);
	}
	
	bool intersects(BoundingBox box) {
		return false;
	}

	bool intersects(vec3 point) {
		return false;
	}
}

class Cube {
	vec3 min, max;

	Cube fromPoints(vec3[] points...) {
		if(points.length == 0) {
			return null;
		}
		
		Cube cube = new Cube();
		
		cube.min = points[0];
		cube.max = points[0];
		foreach(v; points[1..$]) {
			cube.expand(v.vector);
		}
		
		return cube;
	}
	
	Cube fromPoints(float[] points...)  in { assert(points.length % 3 == 0, "Number of points should be divisible by 3"); } 
	body {
		if(points.length == 0) {
			return null;
		}
		
		Cube cube = new Cube();
		
		cube.min = vec3(points[0..3]);
		cube.max = vec3(points[0..3]);
		
		for(int i = 1; i < points.length / 3; i++) {
			cube.expand(to!(float[3])(points[i * 3 .. (i + 1) * 3]));
		}
		
		return cube;
	}

	void expand(float[3] points) {
		if (points[0] > max.x) max.x = points[0];
		if (points[1] > max.y) max.y = points[1];
		if (points[2] > max.z) max.z = points[2];
		if (points[0] < min.x) min.x = points[0];
		if (points[1] < min.y) min.y = points[1];
		if (points[2] < min.z) min.z = points[2];
	}
	
	bool intersects(BoundingBox box) {
		return false;
	}
	
	bool intersects(vec3 point) {
		return false;
	}
}