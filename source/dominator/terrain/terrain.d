module familysurvival.terrain.terrain;

import isolated.graphics.camera.camera;
import isolated.graphics.shader;
import isolated.math;
import isolated.utils.logger;
import isolated.graphics.utils.opengl;

import familysurvival.terrain.tile;

class Terrain {
  private Shader terrainShader;

  public immutable float Tile_Width = 1.0f;
  public immutable float Tile_Height = 1.0f;

  vec2 dimension;
  vec3 position;

  Tile[][] tiles; // X, Y

  this(vec3 position, vec2 dimension) in {assert(dimension.x % Tile_Width == 0 && dimension.y % Tile_Height == 0);}
  body {
    tiles.length = cast(int)(dimension.x / Tile_Width);

    terrainShader = new Shader("Shaders/terrain");

    this.position = position;
    this.dimension = dimension;

    foreach(x; 0..tiles.length) {
      tiles[x].length = cast(int)(dimension.y / Tile_Height);
      Logger.info(tiles[0].length);
      foreach(y; 0..tiles[0].length) {
        tiles[x][y] = new Tile(vec3(position.x + x * Tile_Width, position.y, position.z - y * Tile_Height), Tile_Width, Tile_Height, Tile_Width / 4.0f, Tile_Height / 4.0f);
      }
    }
  }

  void render(Camera camera) {
    terrainShader.bind();
    terrainShader.uniform("uView", camera.viewMatrix);
    terrainShader.uniform("uProjection", camera.projectionMatrix);

    foreach(x; 0..tiles.length) {
      foreach(y; 0..tiles[0].length) {
        tiles[x][y].render(camera);
      }
    }

    terrainShader.unbind();
		checkError();
  }

}
