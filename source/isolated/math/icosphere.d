module isolated.math.icosphere;

class IcoSphere {
	int subdivisionLevel, /* Number of subdivion the sphere has ( only 3, 4 and 5 are supported ) */
		levelCount, /* Number of level the sphere has, depends on the subdivisionLevel */
		levelMaxSize /* First level to have max size, depends on the subdivisionLevel */;

	private vec2[] _intervals; /* Height intervals to determine on which level a triangle resides */

	private vec3[] _positions, _normals; /* Actual position and normal of the sphere in order */
	private vec2[] _texturecoords; /* Actual texture coordinates of the sphere in order */

	this(int subdivisionLevel) {
		this.subdivisionLevel = subdivisionLevel;
		switch(subdivisionLevel) {
			case 3:
				this.levelCount = 6;
				this.levelMaxSize = 5;
				intervals = [vec2(0, 0.25f), vec2(0.27f, 0.5f), vec2(0.52f, 0.72f), vec2(0.73f, 0.89f), vec2(0.9f, 0.96f), vec2(0.97f, 1.0f)];
				break;
			case 4:
				this.levelCount = 12;
				this.levelMaxSize = 9;
				intervals = [vec2(0.0f, 0.1f), vec2(0.17f, 0.24f), vec2(0.28f, 0.37f), vec2(0.38f, 0.49f), vec2(0.49f, 0.596f), vec2(0.598f, 0.7f), vec2(0.7f, 0.8f), vec2(0.8f, 0.87f), vec2(0.88f, 0.93f), vec2(0.93f, 0.97f), vec2(0.97f, 0.99f), vec2(0.99f, 1.0f)];
				break;
			case 5:
				this.levelCount = 24;
				this.levelMaxSize = 17;
				intervals = [vec2(0.0f, 0.05f), vec2(0.08f, 0.12f), vec2(0.15f, 0.19f), vec2(0.2f, 0.26f), vec2(0.27f, 0.324125f), vec2(0.324125f, 0.382f), vec2(0.386f, 0.44f), vec2(0.44f, 0.492f), vec2(0.497f, 0.546099f), vec2(0.546099f, 0.6f), vec2(0.6f, 0.653169f), vec2(0.653169f, 0.701903f), vec2(0.701903f, 0.753809f),
				vec2(0.753809f, 0.801878f), vec2(0.801878f, 0.844915f), vec2(0.844915f, 0.8763f), vec2(0.8763f, 0.909918f), vec2(0.909918f, 0.934339f), vec2(0.934339f, 0.95788f), vec2(0.95788f, 0.972845f), vec2(0.972845f, 0.98495f), vec2(0.98495f, 0.992089f), vec2(0.992089f, 0.997323f), vec2(0.997323f, 1.0f)];
				break;
			default: assert("Such icoSphere is not supported : " ~ to!string(subdivisionLevel) ~ " (subdivisionLevel)");
		}
	}

	/* Calculate where the triangle is in memory */
	int triangleIndex(vec3 v1, vec3 v2, vec3 v3) {
		vec3 middle = (v1 + v2 + v3) / 3.0f;

		foreach(i, interval; intervals) {
			if(middle.y >= interval.x && middle.y <= interval.y) {
				int index = this.levelCount - i;

				return getLevelIndex(index) + triangleLevelCount[index - 1]++;
			}
		}

		Logger.error("Error : " ~ to!string(middle.y) ~ " " ~ to!string(v1.y) ~ " " ~ to!string(v2.y) ~ " " ~ to!string(v3.y));
		readln();
		abort("");
		return 0;
	}

	@safe nothrow int getLevelIndex(int level) {
		if(level >= this.levelMaxSize) {
			int sum = (5 + 5 * (2 * (this.levelMaxSize - 1) - 1)) * (this.levelMaxSize - 1) / 2;
			sum += (pow(2, (this.subdivisionLevel - 3))) * 40 * (level - this.levelMaxSize);

			return sum;
		} else {
			int sum = (5 + 5 * (2 * (level - 1) - 1)) * (level - 1) / 2;
			return sum;
		}
	}

	@safe nothrow int getLevelSize(int level) {
		if(level >= this.levelMaxSize) {
			return pow(2, (this.subdivisionLevel - 3)) * 40;
		} else return 5 * ( 2 * level - 1);
	}
}