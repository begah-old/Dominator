module familysurvival.terrain.tile;

import std.conv;

import isolated.graphics.shader;
import isolated.graphics.mesh;
import isolated.graphics.camera.camera;
import isolated.math;
import isolated.graphics.utils.opengl;
import isolated.utils.logger;
import isolated.window;

import app : window;

class Tile {
  vec2 dimension;
  vec2 tileDimension;
  vec2i tileCount;

  vec3 tilePosition;

  private GLuint VAO;
  private GLuint indicesVBO, positionsVBO;
  private GLuint[] indices;
  private float[] positions;

  /* The dimensions are expressed in meters */
  this(vec3 position, float width, float height, float tileWidth, float tileHeight) in {assert(width % tileWidth == 0 && height % tileHeight == 0);}
  body {
    this.dimension = vec2(width, height);
    this.tilePosition = position;

    this.tileDimension = vec2(tileWidth, tileHeight);
    this.tileCount = vec2i(cast(int)(dimension.x / tileDimension.x), cast(int)(dimension.y / tileDimension.y));

    createTerrainMesh();

    window.addCallBack(&keyCB);
  }

  void keyCB(int key, int action, int mods) nothrow {
    if(key == GLFW_KEY_KP_ADD && action) {
      positions[1] += 0.01f;

      glBindBuffer(GL_ARRAY_BUFFER, positionsVBO);
      glBufferSubData(GL_ARRAY_BUFFER, 1 * float.sizeof, float.sizeof, &positions[1]);
    } else if(key == GLFW_KEY_KP_SUBTRACT && action) {
      positions[1] -= 0.01f;

      glBindBuffer(GL_ARRAY_BUFFER, positionsVBO);
      glBufferSubData(GL_ARRAY_BUFFER, 1 * float.sizeof, float.sizeof, &positions[1]);
    }
  }

  void createTerrainMesh() {
    Mesh mesh;
    int size = 2 + 4 * 2 + (tileCount.y + 1) * (tileCount.x - 1);
    positions = new float[(tileCount.x + 1)*(tileCount.y + 1) * 3];
    indices = new GLuint[tileCount.x * tileCount.y * 6];
    int indicesCursor = 0;
    int positionsCursor = 0;

    foreach(x; 0..tileCount.x + 1) {
      foreach(y; 0..tileCount.y + 1) {
        positions[positionsCursor++] = tilePosition.x + x * tileDimension.x;
        positions[positionsCursor++] = 0;
        positions[positionsCursor++] = tilePosition.z - y * tileDimension.y;

        if(x < tileCount.x && y < tileCount.y) {
          indices[indicesCursor++] = x + y * (tileCount.x + 1);
          indices[indicesCursor++] = (x + 1) + y * (tileCount.x + 1);
          indices[indicesCursor++] = (x + 1) + (y + 1) * (tileCount.x + 1);
          indices[indicesCursor++] = x + y * (tileCount.x + 1);
          indices[indicesCursor++] = (x + 1) + (y + 1) * (tileCount.x + 1);
          indices[indicesCursor++] = x + (y + 1) * (tileCount.x + 1);
        }
      }
    }

    glGenVertexArrays(1, &VAO);
		glBindVertexArray(VAO);

    glGenBuffers(1, &indicesVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STATIC_DRAW);

    glGenBuffers(1, &positionsVBO);
    glBindBuffer(GL_ARRAY_BUFFER, positionsVBO);
    glBufferData(GL_ARRAY_BUFFER, positions.length * float.sizeof, positions.ptr, GL_STATIC_DRAW);
  }

  void render(Camera camera) {
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, positionsVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesVBO);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);

    glDrawElements(GL_TRIANGLES, indices.length, GL_UNSIGNED_INT, null);
  }

  ~this(){

  }
}
