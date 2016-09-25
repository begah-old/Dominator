module dominator.planet.biome;

import isolated.graphics.utils.opengl;

struct Biome {
	@safe nothrow @nogc :

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

	this(Types biomeType, float biomeStrength) {
		this._biomeType = biomeType;
		this._biomeStrength = biomeStrength;
	}

	Color calculateColor() {
		switch(_biomeType) {
			case Types.RAINFOREST:
				return Color(0, 180, 0) * (_biomeStrength / Max_Strenght);
			case Types.FOREST:
				return Color(0, 200, 0) * (_biomeStrength / Max_Strenght);
			case Types.PLAIN:
				return Color(0, 255, 0) * (_biomeStrength / Max_Strenght);
			case Types.SAND_DESERT:
				return Color(255, 255, 0) * (_biomeStrength / Max_Strenght);
			case Types.SNOW_DESERT:
				return Color(100, 100, 255) * (_biomeStrength / Max_Strenght);
			default: return Color(0, 0, 0);
		}
	}
}