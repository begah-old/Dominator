module familysurvival.planet.tile;

import isolated.math;
import isolated.graphics.utils.opengl;

import familysurvival.planet.planet;
import familysurvival.planet.biome;

struct Tile {
	private int _tileID;
	private Planet _planet;

	private VColor _groundColor;

	private Biome _biome;

	this(int tileID, Planet planet) {
		this._tileID = tileID;
		this._planet = planet;

		_biome = Biome(Biome.Types.PLAIN, 3);
		_groundColor = Biome.biomeColor(_biome.biomeType);
	}

	/* Called periodicly, not every frame. time is in second and is the time since the last call of this function */
	void update(float time, Tile*[12] neighbours) {
		int newBiomeStrength = _biome.biomeStrength;
		Biome.Types newBiomeType = _biome.biomeType;

		foreach(tile; neighbours) {
			if(tile._biome.biomeStrength > _biome.biomeStrength) {
				int pressure = tile._biome.biomeStrength - _biome.biomeStrength;
				if(newBiomeType == tile._biome.biomeType) {
					newBiomeStrength += cast(int)round((time / 2.0f) * pressure);
				} else {
					newBiomeStrength -= cast(int)round((time / 4.0f) * pressure);
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