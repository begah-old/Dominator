module dominator.planet.tile;

import isolated.math;
import isolated.graphics.utils.opengl;

import dominator.planet.planet;
import dominator.planet.biome;

struct Tile {
	private int _tileID;
	private Planet _planet;

	private vec3*[3] vertices;

	private VColor _groundColor;

	private Biome _biome;

	this(int tileID, Planet planet) {
		this._tileID = tileID;
		this._planet = planet;

		_biome = Biome(Biome.Types.PLAIN, 3);
		_groundColor = Biome.biomeColor(_biome.biomeType);

		vertices[0] = &_planet.icoSphere.positions[_tileID * 3];
		vertices[1] = &_planet.icoSphere.positions[_tileID * 3 + 1];
		vertices[2] = &_planet.icoSphere.positions[_tileID * 3 + 2];
	}

	/* Called periodicly, not every frame. time is in milliseconds and is the time since the last call of this function */
	void update(long time, Tile*[12] neighbours) {
		int newBiomeStrength = _biome.biomeStrength;
		Biome.Types newBiomeType = _biome.biomeType;

		foreach(tile; neighbours) {
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