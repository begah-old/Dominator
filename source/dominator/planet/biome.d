module dominator.planet.biome;

import isolated.graphics.utils.opengl;

struct Biome {
	enum Types {
		RAINFOREST,
		FOREST,
		PLAIN,
		SAND_DESERT,
		SNOW_DESERT
	}

	private Types _biomeType;
	public Types biomeType() @property { return _biomeType; }

	private int _biomeStrength;
	public ref int biomeStrength() @property { return _biomeStrength; }

	this(Types biomeType, int biomeStrength) {
		this._biomeType = biomeType;
		this._biomeStrength = biomeStrength;
	}

	static VColor biomeColor(Types biome) {
		switch(biome) {
			case Types.RAINFOREST:
				return Color(0, 180, 0);
			case Types.FOREST:
				return Color(0, 200, 0);
			case Types.PLAIN:
				return Color(0, 255, 0);
			case Types.SAND_DESERT:
				return Color(255, 255, 0);
			case Types.SNOW_DESERT:
				return Color(100, 100, 255);
			default: return Color(0, 0, 0);
		}
	}
}