module dominator.planet.planet;

import std.conv;
import std.stdio;
import std.string;
import std.algorithm;

import isolated.math;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;
import isolated.graphics.texture;
import isolated.graphics.utils.opengl;
import isolated.graphics.camera.camera;
import isolated.graphics.shader;
import isolated.utils.logger;
import isolated.file;
import isolated.window;
import isolated.utils.timer;
import app : window;

import dominator.planet.tile;

class Planet {
	private vec3 _position;
	private vec3 _rotation;

	private Mesh _mesh;
	private IcoSphere _icoSphere;
	IcoSphere icoSphere() @property @safe nothrow @nogc { return _icoSphere; }

	private Shader _shader;
	Shader shader() @property @safe nothrow @nogc { return _shader; }

	private Texture _texture;

	private size_t _tileCount;
	private Tile* _tiles;

	private bool wireframe = true, showNeighbours = true;

	private size_t selectedTile = 4712; // TODO: remove
	private size_t lastTile = 0;

	private Camera camera;

	this(vec3 position, int subLevel) {
		_position = position;
		_rotation = vec3(0);

		_timer = Timer().reset;

		_shader = new Shader("Shaders/default");

		_icoSphere = new IcoSphere(subLevel);

		_mesh = new Mesh();
		_mesh.add(VertexAttribute.Position.set(cast(float[])_icoSphere.positions));
		_mesh.add(VertexAttribute.Normal.set(cast(float[])_icoSphere.normals));
		_mesh.add(VertexAttribute.TexCoords.set(cast(float[])_icoSphere.texturecoords));
		_mesh.generate(_shader);

		window.addCallBack(&scroll, true);
		window.addCallBack(&key);

		_texture = Texture(1200, 1200);

		import core.stdc.stdlib : malloc;

		_tileCount = _icoSphere.positions.length / 3;
		_tiles = cast(Tile*)malloc(Tile.sizeof * _tileCount);
		for(int i = 0; i < _tileCount; i++) {
			_tiles[i] = Tile(i, this);
		}
	}

	void scroll(double x, double y) nothrow {
	}

	void key(int key, int action, int mods) nothrow {
		if(!action) return;

		if(key == GLFW_KEY_I) {
			Logger.info("INFO : ");

			/*Logger.info("Texture coordinates : ");
			Logger.info(_icoSphere.texturecoords[selectedTile * 3]);
			Logger.info(_icoSphere.texturecoords[selectedTile * 3 + 1]);
			Logger.info(_icoSphere.texturecoords[selectedTile * 3 + 2]);*/

			Logger.info("Tile id : " ~ selectedTile.to!string);
			Logger.info("Level of tile : " ~ tileLevel(selectedTile).to!string);
			Logger.info("Level index : " ~ _icoSphere.getLevelIndex(tileLevel(selectedTile)).to!string);
			Logger.info("Level size : " ~ _icoSphere.getLevelSize(tileLevel(selectedTile)).to!string);
		} else if(key == GLFW_KEY_U) {
			lastTile = selectedTile;
			selectedTile = tileNeighbourUp(selectedTile);

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_J) {
			lastTile = selectedTile;
			selectedTile = tileNeighbourDown(selectedTile);

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_H) {
			lastTile = selectedTile;
			selectedTile++;

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_K) {
			lastTile = selectedTile;
			selectedTile--;

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_Z && mods == GLFW_MOD_CONTROL) {
			selectedTile = lastTile;
		} else if(key == GLFW_KEY_TAB) {
			wireframe = !wireframe;
		} else if(key == GLFW_KEY_P && mods == GLFW_MOD_CONTROL) {
			showNeighbours = !showNeighbours;
		}
	}

	// Calculate at what level the tile is
	int tileLevel(size_t tileID) @trusted nothrow @nogc {
		int currLevel = _icoSphere.levelCount / 2;
		int size = currLevel;

		while(true) {
			size_t levelIndex = _icoSphere.getLevelIndex(currLevel);
			size_t levelSize = _icoSphere.getLevelSize(currLevel);

			if(tileID >= levelIndex && tileID < levelIndex + levelSize) {
				return currLevel;
			} else if(tileID < levelIndex) {
				currLevel -= size / 2;
				size = cast(int)ceil(size / 2.0);
			} else {
				currLevel += cast(int)ceil(size / 2.0);
				size = cast(int)ceil(size / 2.0);
			}
		}
	}

	size_t tileLeft(size_t tileID) @trusted nothrow @nogc {
		int level = tileLevel(tileID);

		int levelSize = _icoSphere.getLevelSize(level);
		size_t levelIndex = _icoSphere.getLevelIndex(level);

		tileID++;

		if(tileID == levelIndex + levelSize) tileID = levelIndex;

		return tileID;
	}

	size_t tileRight(size_t tileID) @trusted nothrow @nogc {
		if(tileID == 0) return 4;
		int level = tileLevel(tileID);

		int levelSize = _icoSphere.getLevelSize(level);
		size_t levelIndex = _icoSphere.getLevelIndex(level);

		tileID--;

		if(tileID < levelIndex) return levelIndex + levelSize - 1;

		return tileID;
	}

	/* Find tile just below given tile */
	size_t tileNeighbourDown(size_t tileID) @trusted nothrow @nogc {
		int level = tileLevel(tileID);

		int levelSize = _icoSphere.getLevelSize(level);
		size_t levelIndex = _icoSphere.getLevelIndex(level);
		int downLevelSize = _icoSphere.getLevelSize(level + 1);

		if(levelSize == downLevelSize) {
			return tileID + levelSize;
		} else if(levelSize < downLevelSize) {
			int levelSideCount = levelSize / 5; // Tiles count per side
			int numCorners = ( tileID - levelIndex + (levelSideCount / 2) ) / levelSideCount; // Number of corners between first tile and this tile

			size_t newIndex = tileID + levelSize + numCorners * ( (downLevelSize - levelSize) / 5 ); // (downLevelSize - levelSize) / 5 : Calculate how many tiles each corner has ( usually 2 but sometimes 1 )

			return newIndex;
		} else { // Current level is bigger than downard level
			int levelSideCount = levelSize / 5; // Tiles count per side
			int numCorners = ( tileID - levelIndex + ((levelSideCount - 1) / 2) ) / levelSideCount; // Number of corners between first tile and this tile
			size_t newIndex = (levelIndex + levelSize) + (tileID - levelIndex) - numCorners * ( (levelSize - downLevelSize) / 5 );

			return newIndex;
		}
	}

	/* Find tile just above given tile */
	size_t tileNeighbourUp(size_t tileID) @trusted nothrow @nogc {
		if(tileID == 18) return 0;

		int level = tileLevel(tileID);

		int levelSize = _icoSphere.getLevelSize(level);
		size_t levelIndex = _icoSphere.getLevelIndex(level);
		int upLevelSize = _icoSphere.getLevelSize(level - 1);
		size_t upLevelIndex = levelIndex - upLevelSize;

		int levelSideCount, numCorners;
		size_t newIndex;

		if(levelSize == upLevelSize) {
			return tileID - levelSize;
		} else if(levelSize > upLevelSize) {
			levelSideCount = levelSize / 5; // Tiles count per side
			numCorners = ( tileID - levelIndex + ((levelSideCount - 1) / 2) ) / levelSideCount; // Number of corners between first tile and this tile
			newIndex = upLevelIndex + (tileID - levelIndex) - numCorners * ( (levelSize - upLevelSize) / 5 );

			return newIndex;
		} else { // Upper level is bigger than level
			levelSideCount = levelSize / 5; // Tiles count per side
			numCorners = ( tileID - levelIndex + ((levelSideCount - 1) / 2) ) / levelSideCount; // Number of corners between first tile and this tile
			newIndex = tileID - upLevelSize + numCorners * ( (upLevelSize - levelSize) / 5 );

			return newIndex;
		}
	}

	/* Find all tiles sharing atleast one vertex with given tile */
	Tile*[12] tileNeighbours(size_t tileID) @trusted nothrow @nogc {
		Tile*[12] neighbours;

		neighbours[] = null;

		/*size_t index = 0;
		if(tileID < 5) {
			// Place all tiles in first layer as neighbours
			foreach(t; 0 .. 5) {
				if(t == tileID) continue;
				neighbours[index++] = _tiles + t;
			}

			size_t middleNeighbour = tileID + 5 + tileID * 2; // Triangle just under it
			for(int i = -3; i <= 3; i++) {
				if(middleNeighbour + i < 5) {
					neighbours[index++] = _tiles + (middleNeighbour + i + 15);
				} else if(middleNeighbour + i >= 20) {
					neighbours[index++] = _tiles + (middleNeighbour + i - 15);
				} else {
					neighbours[index++] = _tiles + (middleNeighbour + i);
				}
			}

			neighbours[11] = null;
		} else if(tileID >= _tileCount - 5) {
			// Place all tiles in last layer as neighbours
			size_t lastLayer = _tileCount - 6;
			foreach(t; 0 .. 5) {
				if(t == tileID) continue;
				neighbours[index++] = _tiles + (lastLayer + t);
			}

			size_t middleNeighbour = tileID + (tileID - lastLayer) * 2 + (lastLayer - 15); // Triangle just under it
			for(int i = -3; i <= 3; i++) {
				if(middleNeighbour + i < lastLayer - 15) {
					neighbours[index++] = _tiles + (middleNeighbour + i + 15);
				} else if(middleNeighbour + i >= lastLayer) {
					neighbours[index++] = _tiles + (middleNeighbour + i - 15);
				} else {
					neighbours[index++] = _tiles + (middleNeighbour + i);
				}
			}

			neighbours[11] = null;
		} else {
			neighbours[index++] = &_tiles[tileNeighbourUp(tileID)];
			neighbours[index++] = &_tiles[tileNeighbourDown(tileID)];
			neighbours[index++] = &_tiles[tileLeft(tileID)];
			neighbours[index++] = &_tiles[tileRight(tileID)];
		}*/

		return neighbours;
	}

	private Timer _timer;
	void update(Camera camera, float delta) {
		if(_timer.elapsedTime >= 1000) {
			foreach(i, ref tile; _tiles[0 .. _tileCount]) {
				tile.update(_timer.elapsedTime, tileNeighbours(i));
			}
			_timer.reset;
		}
	}

	void render(Camera camera) {
		this.camera = camera;
		checkError();

		_shader.bind();
		_shader.uniform("uView", camera.viewMatrix);
		_shader.uniform("uProjection", camera.projectionMatrix);
		_shader.uniform("uTransform", mat4.identity);

		_shader.uniform(_shader.textureSamplers[0], 0);

		glBindVertexArray(_mesh.vao);

		_texture.bind();

		if(showNeighbours) {
			Tile*[12] neighbours = tileNeighbours(selectedTile);

			foreach(i; 0 .. 12) {
				if(neighbours[i] is null) break;

				_shader.uniform("Color", Color(0, 255, 0));
				glDrawArrays(GL_TRIANGLES, neighbours[i].tileID * 3, 3);
			}
		}

		_shader.uniform("Color", Color(255));
		glDrawArrays(GL_TRIANGLES, 0, _mesh.vertexCount);

		if(wireframe) {
			_shader.uniform("Color", Color(0, 0, 255));
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
			glDrawArrays(GL_TRIANGLES, 0, _mesh.vertexCount);
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		}

		glDisable(GL_DEPTH_TEST);

		_shader.uniform("Color", Color(255, 0, 0));
		glDrawArrays(GL_TRIANGLES, selectedTile * 3, 3);

		glBindVertexArray(0);

		_texture.unbind();
		_shader.unbind();
		checkError();
	}

	void triangleChangeColor(int triangle, VColor color) {
		_texture.changePixels(_icoSphere.texturecoords[triangle * 3],
							  _icoSphere.texturecoords[triangle * 3 + 1],
							  _icoSphere.texturecoords[triangle * 3 + 2],
							  color);
	}
}
