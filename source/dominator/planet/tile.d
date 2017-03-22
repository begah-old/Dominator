module dominator.planet.tile;

import isolated.math;
import isolated.graphics.utils.opengl;
import isolated.utils.logger;

import dominator.planet.planet;
import dominator.planet.biome;

struct Tile {
	private size_t _id;
	ref size_t id() @property { return _id; }

	Planet planet;

	private vec3[3] _vertices;
	vec3[3] vertices() @property {return _vertices;}

	private vec3 _normal;
	vec3 normal() @property {return _normal;}

	Color _groundColor;

	static immutable float BIOME_CHANGE_CONSTANT = 1f; // How hard it is to put pressure on a biome and force it to change

	private Biome _biome;
	Biome _newBiome;
	ref Biome biome() @property {return _biome;}

	Tile*[12] neighbours;

	this(size_t id, Planet planet) {
		this._id = id;
		this.planet = planet;

		_biome = Biome(Biome.Types.PLAIN, 3, Biome.Types.PLAIN);
		_newBiome = _biome;

		_vertices = planet.icoSphere.positions[id * 3 .. (id + 1) * 3];
		_normal = planet.icoSphere.normals[id * 3];

		neighbours = getNeighbours();

		setColor(_biome.calculateColor());
	}

	/* Called periodicly, not every frame. time is in milliseconds and is the time since the last call of this function 
		Update the biome*/
	void updateBiome(double time) {
		const float BIOME_PRESSURE_CONSTANT = 10.0f;
		_newBiome = _biome;

		float totalPressure = 0;
		float maxPressure = 0; // Biome to exerce the most pressure on tile
		Biome.Types maxPressureID = Biome.Types.NONE; // Biome id to exerce the most pressure on tile
		int tilePressureCount;

		foreach(tile; neighbours) {
			if(tile is null) break;

			if(tile._biome.biomeType == _biome.biomeType)
				totalPressure -= (tile._biome.biomeStrength / (_biome.biomeStrength * BIOME_PRESSURE_CONSTANT));
			else {
				totalPressure += (tile._biome.biomeStrength / (_biome.biomeStrength * BIOME_PRESSURE_CONSTANT));
				
				if(tile._biome.biomeStrength > maxPressure) {
					maxPressure = tile._biome.biomeStrength;
					maxPressureID = tile._biome.biomeType;
				}
			}
			tilePressureCount++;
		}

		_newBiome.biomeStrengthRef -= totalPressure;
		if(_newBiome.biomeStrength < 0) {
			_newBiome.nextBiomeType = _newBiome.biomeType;
			_newBiome.biomeType = maxPressureID;
			_newBiome.biomeStrengthRef *= -1.0f;
		} else {
			if(_newBiome.biomeStrength > Biome.Max_Strenght)
				_newBiome.biomeStrengthRef = Biome.Max_Strenght;
			_newBiome.nextBiomeType = maxPressureID;
		}

		setColor(_newBiome.calculateColor());
	}

	void update(double time) {
		_biome = _newBiome;
	}

	void setColor(Color color) {
		_groundColor = color;

		planet._colorAttributes.replace(id * 3, id * 3, [color.r / 255.0f, color.g / 255.0f, color.b / 255.0f, color.a / 255.0f, color.r / 255.0f, color.g / 255.0f, color.b / 255.0f, color.a / 255.0f, color.r / 255.0f, color.g / 255.0f, color.b / 255.0f, color.a / 255.0f]);
	}

	void setBiome(Biome biome) {
		_biome = _newBiome = biome;
		setColor(biome.calculateColor());
	}

	/// Return the vertices in common between the two tiles
	vec3[3] commonVertices(size_t otherTile) {
		vec3[3] commonVertices = vec3(0);
		size_t index;

		foreach(v1; vertices) {
			foreach(v2; planet.tiles[otherTile].vertices) {
				if(v1 == v2) {
					commonVertices[index++] = v1;
					break;
				}
			}
		}

		return commonVertices;
	}

	/// Find all tiles sharing atleast one vertex with given tile
	Tile*[12] getNeighbours() {
		Tile*[12] neighbours;
		neighbours[] = null;
		size_t index;

		if(id < 5) {
			// Place all tiles in first layer as neighbours
			foreach(t; 0 .. 5) {
				if(t == id) continue;
				neighbours[index++] = planet.tiles + t;
			}

			size_t middleNeighbour = planet.icoSphere.Tile_NeighbourDown(id); // Triangle just under it
			for(int i = -3; i <= 3; i++) {
				neighbours[index++] = planet.tiles + planet.icoSphere.Tile_ToLevel(middleNeighbour + i, 2);
			}
		} else if(id >= planet.tileCount - 5) {
			// Place all tiles in last layer as neighbours
			size_t lastLayer = planet.tileCount - 5;
			foreach(t; 0 .. 5) {
				if(t == id - lastLayer) continue;
				neighbours[index++] = planet.tiles + (lastLayer + t);
			}

			size_t middleNeighbour = planet.icoSphere.Tile_NeighbourUp(id); // Triangle just above it
			for(int i = -3; i <= 3; i++) {
				neighbours[index++] = planet.tiles + planet.icoSphere.Tile_ToLevel(middleNeighbour + i, planet.icoSphere.levelCount - 1 );
			}
		} else {
			/// Returns number of vertices shared by tiles
			size_t pointsShared(size_t tileID, size_t neighbourID) {
				size_t count;

				foreach(v1; planet.icoSphere.positions[tileID * 3 .. (tileID + 1) * 3]) {
					foreach(v2; planet.icoSphere.positions[neighbourID * 3 .. (neighbourID + 1) * 3]) {
						if(v1 == v2) count++;
					}
				}

				return count;
			}

			void put(size_t tile) {
				neighbours[index++] = planet.tiles + tile;
			}

			size_t levelID = planet.icoSphere.Tile_Level(id);

			// Check left tiles
			foreach(i; -4 .. 5) {
				if(i && pointsShared(id, planet.icoSphere.Tile_ToLevel(id + i, levelID))) {
					put(planet.icoSphere.Tile_ToLevel(id + i, levelID));
				}
			}

			// Check above tiles
			size_t currentTile = planet.icoSphere.Tile_NeighbourUp(id);

			foreach(i; -3 .. 4) {
				if(pointsShared(id, planet.icoSphere.Tile_ToLevel(currentTile + i, levelID - 1))) {
					put(planet.icoSphere.Tile_ToLevel(currentTile + i, levelID - 1));
				}
			}

			// Check downard tiles
			currentTile = planet.icoSphere.Tile_NeighbourDown(id);

			foreach(i; -3 .. 4) {
				if(pointsShared(id, planet.icoSphere.Tile_ToLevel(currentTile + i, levelID + 1))) {
					put(planet.icoSphere.Tile_ToLevel(currentTile + i, levelID + 1));
				}
			}
		}

		return neighbours;
	}

	~this() {

	}
}
