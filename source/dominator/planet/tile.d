module dominator.planet.tile;

import isolated.math;
import isolated.graphics.utils.opengl;

import dominator.planet.planet;
import dominator.planet.biome;

struct Tile {
	private size_t _tileID;
	ref size_t tileID() @property nothrow @safe @nogc { return _tileID; }

	private Planet _planet;

	private vec3[3] _vertices;
	vec3[3] vertices() nothrow @property @nogc @safe {return _vertices;}

	private vec3 _normal;
	vec3 normal() nothrow @property @nogc @safe {return _normal;}

	private vec2[3] _textucoords;
	vec2[3] textucoords() nothrow @property @nogc @safe {return _textucoords;}

	private VColor _groundColor;

	private Biome _biome;

	this(size_t tileID, Planet planet) {
		this._tileID = tileID;
		this._planet = planet;

		_biome = Biome(Biome.Types.PLAIN, 3);
		_groundColor = Biome.biomeColor(_biome.biomeType);

		_vertices = _planet.icoSphere.positions[_tileID * 3 .. (_tileID + 1) * 3];
		_normal = _planet.icoSphere.normals[_tileID * 3];
		_textucoords = _planet.icoSphere.texturecoords[_tileID * 3 .. (_tileID + 1) * 3];
	}

	/* Called periodicly, not every frame. time is in milliseconds and is the time since the last call of this function */
	void update(long time, Tile*[12] neighbours) {
		int newBiomeStrength = _biome.biomeStrength;
		Biome.Types newBiomeType = _biome.biomeType;

		foreach(tile; neighbours) {
			if(tile is null) break;
			if(tile._biome.biomeStrength > _biome.biomeStrength) {
				int pressure = tile._biome.biomeStrength - _biome.biomeStrength;
				if(newBiomeType == tile._biome.biomeType) {
					newBiomeStrength += cast(int)round((time / 2000.0f) * pressure);
				} else {
					newBiomeStrength -= cast(int)round((time / 4000.0f) * pressure);
					if(newBiomeStrength < 0) {
						newBiomeType = tile._biome.biomeType;
						newBiomeStrength *= -1;
					}
				}
			}
		}
	}

	~this() {

	}
}