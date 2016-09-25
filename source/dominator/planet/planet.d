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
import dominator.planet.biome;

class Planet {
	private vec3 _position;
	private vec3 _rotation;

	private Mesh _mesh;
	private IcoSphere _icoSphere;
	IcoSphere icoSphere() @property @safe nothrow @nogc { return _icoSphere; }
	
	private BoundingCube _boundingCube;
	BoundingCube getBoundingBox() @property @safe nothrow @nogc { return _boundingCube; }

	private Shader _shader;
	Shader shader() @property @safe nothrow @nogc { return _shader; }

	private Texture _texture;
	ref Texture texture() @property @safe nothrow @nogc { return _texture; }

	private size_t _tileCount;
	size_t tileCount() @property @safe nothrow @nogc { return _tileCount; }
	private Tile* _tiles;
	Tile* tiles() @property @safe nothrow @nogc { return _tiles; }

	bool wireframe = true, showNeighbours = true;

	size_t selectedTile = 0; // TODO: remove
	private size_t lastTile = 0; // TODO: remove

	private Camera camera;

	this(vec3 position, int subLevel) {
		_position = position;
		_rotation = vec3(0);

		_timer = Timer().reset;

		_shader = new Shader("Shaders/default");

		_icoSphere = new IcoSphere(subLevel);
		_boundingCube = new BoundingCube();
		_boundingCube.max = vec3(1.0f); _boundingCube.min = vec3(0.0f);

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
			_tiles[i] = Tile(i, this, vec2i(_texture.width, _texture.height));
		}
	}

	void scroll(double x, double y) nothrow {
	}

	void key(int key, int action, int mods) nothrow {
		if(!action) return;

		if(key == GLFW_KEY_I) {
			Logger.info("INFO : ");

			Logger.info("Tile id : " ~ selectedTile.to!string);
			Logger.info("Level of tile : " ~ _icoSphere.Tile_Level(selectedTile).to!string);
			Logger.info("Level index : " ~ _icoSphere.getLevelIndex(_icoSphere.Tile_Level(selectedTile)).to!string);
			Logger.info("Level size : " ~ _icoSphere.getLevelSize(_icoSphere.Tile_Level(selectedTile)).to!string);
		} else if(key == GLFW_KEY_U && selectedTile >= 5) {
			lastTile = selectedTile;
			selectedTile = _icoSphere.Tile_NeighbourUp(selectedTile);

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_J && selectedTile < _tileCount - 5) {
			lastTile = selectedTile;
			selectedTile = _icoSphere.Tile_NeighbourDown(selectedTile);

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_H && selectedTile < _tileCount - 1) {
			lastTile = selectedTile;
			selectedTile++;

			vec3 middle = (_tiles[selectedTile].vertices[0] + _tiles[selectedTile].vertices[1] + _tiles[selectedTile].vertices[2]) / 3.0f, normal = _tiles[selectedTile].normal;
			camera.moveToLookAt(middle + normal * 1, middle);
		} else if(key == GLFW_KEY_K && selectedTile > 0) {
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
		} else if(key == GLFW_KEY_ENTER) {
			_texture.changePixels(vec2(0), vec2(1, 0), vec2(1), Color(255, 0, 0));
			_texture.changePixels(vec2(0), vec2(1), vec2(0, 1), Color(255, 0, 0));

			foreach(ref tile; _tiles[0 .. tileCount]) {
				tile.setColor(tile._groundColor);
			}
		} else if(key == GLFW_KEY_0) {
			_tiles[selectedTile].biome = _tiles[selectedTile]._newBiome = Biome(Biome.Types.SAND_DESERT, Biome.Max_Strenght);
			_tiles[selectedTile].setColor(_tiles[selectedTile].biome.calculateColor());
		}
	}

	private Timer _timer;
	void update(Camera camera, float delta) {
		if(_timer.elapsedTime >= 1000) {
			foreach(i, ref tile; _tiles[0 .. _tileCount]) {
				tile.updateBiome(_timer.elapsedTime);
			}
			_timer.reset;
		}
		foreach(i, ref tile; _tiles[0 .. _tileCount]) {
			tile.update(delta);
		}
	}

	void render(Camera camera) {
		this.camera = camera;
		checkError();

		if(_texture.isDirty) {
			_texture.bind();
			checkError();
		}

		_shader.bind();
		_shader.uniform("uView", camera.viewMatrix);
		_shader.uniform("uProjection", camera.projectionMatrix);
		_shader.uniform("uTransform", mat4.identity);

		_shader.uniform(_shader.textureSamplers[0], 0);

		glBindVertexArray(_mesh.vao);

		_texture.bind();

		_shader.uniform("Color", Color(255, 0, 0));
		glDrawArrays(GL_TRIANGLES, selectedTile * 3, 3);

		_shader.uniform("Color", Color(255));
		glDrawArrays(GL_TRIANGLES, 0, _mesh.vertexCount);

		glBindVertexArray(0);

		_texture.unbind();
		_shader.unbind();
		checkError();
	}
}
