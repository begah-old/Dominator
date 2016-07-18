module icosphere;

import std.conv;
import std.stdio;
import std.string;
import std.algorithm;
import std.math : pow, abs;
import core.internal.abort;
import std.range;
import std.array;

import gl3n.linalg;

struct Logger {
  static void info(T) (T t) {
    writeln(t);
  }

  alias error = info;
}

struct Vertex {
  vec3 position;
  vec3 normal;
  vec2 textcoord;
}

Vertex[] ReadFile(int subdivisionLevel) {
  File f = File("C:/Users/Begah/Documents/Dominator/tools/IcoSphere Generator/assets/" ~ to!string(subdivisionLevel) ~ ".obj");

  vec3[] vertices, normals;
  vec2[] textcoords;
  vec3i[] facesVertices, facesNormals, facesTextcoords;

  foreach(line; f.byLine) {
    if(line.length <= 2) continue;

    auto splits = split(line);

    switch(splits[0]) {
      case "v":
        vertices ~= vec3(to!(float[])(splits[1 .. $]));
        break;
      case "vn":
        normals ~= vec3(to!(float[])(splits[1 .. $]));
        break;
      case "vt":
        textcoords ~= vec2(to!(float[])(splits[1 .. $]));
        break;
      case "f":
        splits = splits[1 .. $];

        int[3] process(char[] splits) {
          char[][] str = split(splits, "/");
          foreach(ref s; str) {
            if(s == "") {
              s = "-1".dup;
            }
          }
          return to!(int[3])(str);
        }

        int[3] integers = process(splits[0]);
        int[3] integers2 = process(splits[1]);
        int[3] integers3 = process(splits[2]);

        if(integers[0] != -1) {
          facesVertices ~= vec3i(integers[0] - 1, integers2[0] - 1, integers3[0] - 1);
        }
        if(integers[1] != -1) {
          facesTextcoords ~= vec3i(integers[1] - 1, integers2[1] - 1, integers3[1] - 1);
        }
        if(integers[2] != -1) {
          facesNormals ~= vec3i(integers[2] - 1, integers2[2] - 1, integers3[2] - 1);
        }
        break;
      default:break;
    }
  }

  Vertex[] unorganizedVertices = new Vertex[facesVertices.length * 3];

  if(facesNormals.length == 0) {
    facesNormals = vec3i(0).repeat(facesVertices.length).array;
    normals = [vec3(0)];
  }
  if(facesTextcoords.length == 0) {
    facesTextcoords = vec3i(0).repeat(facesVertices.length).array;
    textcoords = [vec2(0)];
  }

  foreach(i; 0..facesVertices.length) {
    unorganizedVertices[i * 3] = Vertex(vertices[facesVertices[i].x], normals[facesNormals[i].x], textcoords[facesTextcoords[i].x]);
    unorganizedVertices[i * 3 + 1] = Vertex(vertices[facesVertices[i].y], normals[facesNormals[i].y], textcoords[facesTextcoords[i].y]);
    unorganizedVertices[i * 3 + 2] = Vertex(vertices[facesVertices[i].z], normals[facesNormals[i].z], textcoords[facesTextcoords[i].z]);
  }

  return unorganizedVertices;
}

class IsoSphere {
  int subdivisionLevel, /* Number of subdivion the sphere has ( only 3, 4 and 5 are supported ) */
    levelCount, /* Number of level the sphere has, depends on the subdivisionLevel */
    levelMaxSize /* First level to have max size, depends on the subdivisionLevel */;
  Vertex[] vertices;

  private vec2[] intervals; /* Height intervals to determine on which level a triangle resides */

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

    Vertex[] unorganizedVertices = ReadFile(subdivisionLevel);

    vertices = new Vertex[unorganizedVertices.length];

    for(int _i = 0; _i < unorganizedVertices.length; _i += 3) {
		if(unorganizedVertices[_i + 2].position.y != 1) continue;

		void workLevel(int level) {
			void writeTriangle(int index, Vertex v1, Vertex v2, Vertex vother) { // Write and organised triangle to verts. v1 and v2 are considered the vertices shared with previous triangle
				float len1 = abs(v1.position.xz.magnitude - vother.position.xz.magnitude);
				float len2 = abs(v2.position.xz.magnitude - vother.position.xz.magnitude);

				if(len1 > len2) {
					vertices[index] = v2;
					vertices[index + 1] = vother;
					vertices[index  +2] = v1;
				} else {
					vertices[index] = v1;
					vertices[index + 1] = vother;
					vertices[index  +2] = v2;
				}
			}

			if(level != 1) {
				// Find triangle that is connected to above triangle
				int index = getLevelIndex(level - 1) * 3;

				Vertex base1, base2, point; // Base and the last vertices of the triange to connect too

				float len1 = abs(vertices[index].position.y - vertices[index + 1].position.y);
				float len2 = abs(vertices[index].position.y - vertices[index + 2].position.y);
				float len3 = abs(vertices[index + 1].position.y - vertices[index + 2].position.y);

				if(len1 < len2 && len1 < len3) {
					base1 = vertices[index];
					base2 = vertices[index + 1];
					point = vertices[index + 2];
				} else if(len2 < len1 && len2 < len3) {
					base1 = vertices[index];
					base2 = vertices[index + 2];
					point = vertices[index + 1];
				} else {
					base1 = vertices[index + 1];
					base2 = vertices[index + 2];
					point = vertices[index];
				}

				if(base1.position.y > point.position.y && base2.position.y > point.position.y) { // Only a point to work with ( Triangle is downwards )
					Logger.info("Level : " ~ to!string(level) ~ " is connected too one point");
					index = getLevelIndex(level) * 3;

					for(int i = 0; i < unorganizedVertices.length; i += 3) {
						if(point.position != unorganizedVertices[i + 2].position || !almost_equal(unorganizedVertices[i].position.y, unorganizedVertices[i + 1].position.y, 0.001f)) continue;

						vertices[index] = unorganizedVertices[i];
						vertices[index + 1] = unorganizedVertices[i + 1];
						vertices[index + 2] = unorganizedVertices[i + 2];
						break;
					}
				} else { // Two points to work with ( Triangle is upwards )
					Logger.info("Level : " ~ to!string(level) ~ " is connected too two points");
					index = getLevelIndex(level) * 3;

					for(int i = 0; i < unorganizedVertices.length; i += 3) {
						int hasBase1 = base1.position.among(unorganizedVertices[i].position, unorganizedVertices[i + 1].position, unorganizedVertices[i + 2].position);
						int hasBase2 = base2.position.among(unorganizedVertices[i].position, unorganizedVertices[i + 1].position, unorganizedVertices[i + 2].position);
						int hasNotOther = point.position.among(unorganizedVertices[i].position, unorganizedVertices[i + 1].position, unorganizedVertices[i + 2].position);
						if(hasBase1 && hasBase2 && hasNotOther == 0) {
							vertices[index] = unorganizedVertices[i + (hasBase1 - 1)];
							vertices[index + 2] = unorganizedVertices[i + (hasBase2 - 1)];

							if(hasBase1 != 1 && hasBase2 != 1) vertices[index + 1] = unorganizedVertices[i];
							if(hasBase1 != 2 && hasBase2 != 2) vertices[index + 1] = unorganizedVertices[i + 1];
							if(hasBase1 != 3 && hasBase2 != 3) vertices[index + 1] = unorganizedVertices[i + 2];
							break;
						}
					}
				}
			}

			// Fill up level
			int index = getLevelIndex(level) * 3;
			int size = getLevelSize(level);

			Loop : foreach(i; 1..size) {
				Vertex vother = vertices[index + (i - 1) * 3];
				Vertex v1 = vertices[index + (i - 1) * 3 + 1];
				Vertex v2 = vertices[index + (i - 1) * 3 + 2];

				for(int i2 = 0; i2 < unorganizedVertices.length; i2 += 3) {
					int hasV1 = v1.position.among(unorganizedVertices[i2].position, unorganizedVertices[i2 + 1].position, unorganizedVertices[i2 + 2].position);
					int hasV2 = v2.position.among(unorganizedVertices[i2].position, unorganizedVertices[i2 + 1].position, unorganizedVertices[i2 + 2].position);
					int hasOther = vother.position.among(unorganizedVertices[i2].position, unorganizedVertices[i2 + 1].position, unorganizedVertices[i2 + 2].position);
					
					if(hasV1 && hasV2 && hasOther == 0) {
						Vertex other;
						if(hasV1 != 1 && hasV2 != 1)
							other = unorganizedVertices[i2];
						else if(hasV1 != 2 && hasV2 != 2)
							other = unorganizedVertices[i2 + 1];
						else
							other = unorganizedVertices[i2 + 2];

						writeTriangle(index + i * 3, unorganizedVertices[i2 + (hasV1 - 1)], unorganizedVertices[i2 + (hasV2 - 1)], other);
						continue Loop;
					}
				}
			}
		}

		vertices[0] = unorganizedVertices[_i];
		vertices[1] = unorganizedVertices[_i + 1];
		vertices[2] = unorganizedVertices[_i + 2];

		foreach(level; 1..this.levelCount+1) {
			workLevel(level);
		}
		break;
	}
  }

  /* Calculate where the triangle is in memory */
  int triangleIndex(vec3 v1, vec3 v2, vec3 v3) {
    vec3 middle = (v1 + v2 + v3) / 3.0f;

    foreach(i, interval; intervals) {
      if(middle.y >= interval.x && middle.y <= interval.y) {
        int index = this.levelCount - i;

        return getLevelIndex(index);
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
