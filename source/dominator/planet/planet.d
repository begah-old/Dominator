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

import dominator.main;
import dominator.planet.tile;
import dominator.planet.biome;

import shared_memory;

class Planet {
	Dominator dominator;

	private vec3 _position;
	private vec3 _rotation;

	private Mesh _mesh;
	VertexAttribute _positionAttributes;
	VertexAttribute _normalAttributes;
	VertexAttribute _colorAttributes;

	private IcoSphere _icoSphere;
	IcoSphere icoSphere() @property { return _icoSphere; }
	
	private BoundingCube _boundingCube;
	BoundingCube getBoundingBox() @property { return _boundingCube; }

	private static Shader _shader;
	static Shader shader() @property{ return _shader; }

	private size_t _tileCount;
	size_t tileCount() @property { return _tileCount; }

	private Tile* _tiles;
	Tile* tiles() @property { return _tiles; }

	this(Dominator dominator, vec3 position, int subLevel) {
		this.dominator = dominator;
		_position = position;
		_rotation = vec3(0);

		_timer = Timer().reset;

		if(_shader is null) {
			_shader = new Shader("default");
		}

		_icoSphere = new IcoSphere(subLevel);
		_boundingCube = new BoundingCube();
		_boundingCube.max = vec3(1.0f); _boundingCube.min = vec3(0.0f);

		mainWindow.addCallBack(&scroll, true);
		mainWindow.addCallBack(&key);

		import core.stdc.stdlib : malloc;
		_tileCount = _icoSphere.positions.length / 3;
		_tiles = cast(Tile*)malloc(Tile.sizeof * _tileCount);

		_mesh = new Mesh();
		_mesh.add((_positionAttributes = VertexAttribute.Position.set(cast(float[])_icoSphere.positions).toggleDynamic));
		_mesh.add((_normalAttributes = VertexAttribute.Normal.set(cast(float[])_icoSphere.normals)));
		_mesh.add((_colorAttributes = VertexAttribute.ColorPacked.set(cast(float[])(cast(float*)malloc(_tileCount * 4 * 3 * float.sizeof))[0 .. _tileCount * 12]).toggleDynamic));
		_mesh.generate(_shader);

		for(int i = 0; i < _tileCount; i++) {
			_tiles[i] = Tile(i, this);
		}
	}

	void scroll(double x, double y) {
	}

	void key(int key, int action, int mods) {
		if(!action) return;
	}

	private Timer _timer;
	void update(Camera camera, double delta) {
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
		checkError();

		_colorAttributes.refresh();

		_shader.bind();
		_shader.uniform("uView", camera.viewMatrix);
		_shader.uniform("uProjection", camera.projectionMatrix);
		_shader.uniform("uTransform", mat4.identity);

		glBindVertexArray(_mesh.vao);

		_shader.uniform("ColorControl", Color.White);
		glDrawArrays(GL_TRIANGLES, 0, cast(GLint)_mesh.vertexCount);

		if(dominator.selectedTile.length != 0 && dominator.selectedTile[0].planet == this) {
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
			_shader.uniform("ColorControl", Color.Black);
			foreach(t; dominator.selectedTile) {
				glDrawArrays(GL_TRIANGLES, cast(GLint)t.id * 3, 3);
			}
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
			_shader.uniform("ColorControl", Color.White);
		}

		glBindVertexArray(0);

		_shader.unbind();
		checkError();
	}
}
