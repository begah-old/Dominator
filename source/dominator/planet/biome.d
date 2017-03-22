module dominator.planet.biome;

import isolated.graphics.utils.opengl;

struct Biome {
	enum Types {
		NONE,
		RAINFOREST,
		FOREST,
		PLAIN,
		SAND_DESERT,
		SNOW_DESERT
	}
	enum Max_Strenght = 3.0f;

	private Types _biomeType;
	public ref Types biomeType() @property { return _biomeType; }

	private float _biomeStrength;
	public float biomeStrength() @property { return _biomeStrength; }
	public ref float biomeStrengthRef() @property { return _biomeStrength; }

	public Types nextBiomeType; /// Type of biome that current biome will change too

	this(Types biomeType, float biomeStrength, Types nextBiomeType) {
		this._biomeType = biomeType;
		this._biomeStrength = biomeStrength;
		this.nextBiomeType = nextBiomeType;
	}

	private Color calculateNextBiomeColor() {
		switch(nextBiomeType) {
			case Types.RAINFOREST:
				return Color(0, 180, 0) * ((Max_Strenght - _biomeStrength) / Max_Strenght);
			case Types.FOREST:
				return Color(0, 200, 0) * ((Max_Strenght - _biomeStrength) / Max_Strenght);
			case Types.PLAIN:
				return Color(0, 255, 0) * ((Max_Strenght - _biomeStrength) / Max_Strenght);
			case Types.SAND_DESERT:
				return Color(255, 255, 0) * ((Max_Strenght - _biomeStrength) / Max_Strenght);
			case Types.SNOW_DESERT:
				return Color(100, 100, 255) * ((Max_Strenght - _biomeStrength) / Max_Strenght);
			default: return Color(0, 0, 0);
		}
	}

	Color calculateColor() {
		switch(_biomeType) {
			case Types.RAINFOREST:
				return Color(0, 180, 0) * (_biomeStrength / Max_Strenght) + calculateNextBiomeColor();
			case Types.FOREST:
				return Color(0, 200, 0) * (_biomeStrength / Max_Strenght) + calculateNextBiomeColor();
			case Types.PLAIN:
				return Color(0, 255, 0) * (_biomeStrength / Max_Strenght) + calculateNextBiomeColor();
			case Types.SAND_DESERT:
				return Color(255, 255, 0) * (_biomeStrength / Max_Strenght) + calculateNextBiomeColor();
			case Types.SNOW_DESERT:
				return Color(100, 100, 255) * (_biomeStrength / Max_Strenght) + calculateNextBiomeColor();
			default: return Color(0, 0, 0);
		}
	}
}