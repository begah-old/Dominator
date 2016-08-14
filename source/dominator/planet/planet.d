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
	private int level; // TODO: Remove

	private Texture _texture;

	private uint _tileCount;
	private Tile* _tiles;

	private bool wireframe = false;

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

		level = 0;

		_texture = Texture(1200, 1200);

		import core.stdc.stdlib : malloc;

		_tileCount = _icoSphere.positions.length / 3;
		_tiles = cast(Tile*)malloc(Tile.sizeof * _tileCount);
		for(int i = 0; i < _tileCount; i++) {
			_tiles[i] = Tile(i, this);
		}
	}

	void scroll(double x, double y) nothrow {
		level -= cast(int)y;

		if(level > _icoSphere.levelCount)
			level = 1;
		if(level < 0)
			level = _icoSphere.levelCount;
	
		Logger.info(level);
		Logger.info(to!string(_icoSphere.getLevelIndex(level)) ~ " / " ~ to!string(_icoSphere.getLevelSize(level)));
	}

	void key(int key, int action, int mods) nothrow {
		if(!action) return;

		if(key == GLFW_KEY_I) {
			Logger.info("INFO");
			Logger.info(_icoSphere.texturecoords[_icoSphere.getLevelIndex(level) * 3]);
			Logger.info(_icoSphere.texturecoords[_icoSphere.getLevelIndex(level) * 3 + 1]);
			Logger.info(_icoSphere.texturecoords[_icoSphere.getLevelIndex(level) * 3 + 2]);
		} else if(key == GLFW_KEY_UP) {
			level--;
		} else if(key == GLFW_KEY_DOWN) {
			level++;
		} else if(action == GLFW_PRESS && key == GLFW_KEY_TAB) {
			wireframe = !wireframe;
		}
	}

	Tile*[12] tileNeighbours(uint tileID) {
		Tile*[12] neighbours;

		int index = 0;
		if(tileID < 5) {
			// Place all tiles in first layer as neighbours
			foreach(t; 0 .. 5) {
				if(t == tileID) continue;
				neighbours[index++] = _tiles + t;
			}

			int middleNeighbour = tileID + 5 + tileID * 2; // Triangle just under it
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
			int lastLayer = _tileCount - 6;
			foreach(t; 0 .. 5) {
				if(t == tileID) continue;
				neighbours[index++] = _tiles + (lastLayer + t);
			}

			int middleNeighbour = tileID + (tileID - lastLayer) * 2 + (lastLayer - 15); // Triangle just under it
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

		}

		return neighbours;
	}

	private Timer _timer;
	void update() {
		if(_timer.elapsedTime >= 1000) {
			foreach(i, ref tile; _tiles[0 .. _tileCount]) {
				tile.update(_timer.elapsedTime, tileNeighbours(i));
			}
			_timer.reset;
		}
	}

	void render(Camera camera) {
		_shader.bind();
		_shader.uniform("uView", camera.viewMatrix);
		_shader.uniform("uProjection", camera.projectionMatrix);

		_shader.uniform(_shader.textureSamplers[0], 0);

		glBindVertexArray(_mesh.vao);

		int start, count;
		if(level == 0) {
			start = 0;
			count = _mesh.vertexCount;
		} else {
			start =	_icoSphere.getLevelIndex(level) * 3;
			count =	_icoSphere.getLevelSize(level) * 3;
		}

		_texture.bind();

		if(wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		glDrawArrays(GL_TRIANGLES, start, count);
		if(wireframe) glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

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
