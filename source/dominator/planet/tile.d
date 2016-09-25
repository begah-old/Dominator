module dominator.planet.tile;

import isolated.math;
import isolated.graphics.utils.opengl;
import isolated.utils.logger;

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

	private vec2[3] _texturecoords;
	vec2[3] texturecoords() nothrow @property @nogc @safe {return _texturecoords;}

	private vec2[3] _colorTexturecoords; /* Texture coordinates to utilise when coloring texture, makes sure all pixels are colored */

	Color _groundColor;

	static immutable float BIOME_CHANGE_CONSTANT = 1f; // How hard it is to put pressure on a biome and force it to change

	private Biome _biome;
	Biome _newBiome;
	ref Biome biome() nothrow @property @nogc @safe {return _biome;}

	Tile*[12] neighbours;

	this(size_t tileID, Planet planet, vec2i textureSize) {
		this._tileID = tileID;
		this._planet = planet;

		_biome = Biome(Biome.Types.PLAIN, 3);
		_newBiome = _biome;

		_vertices = _planet.icoSphere.positions[_tileID * 3 .. (_tileID + 1) * 3];
		_normal = _planet.icoSphere.normals[_tileID * 3];
		_texturecoords = _planet.icoSphere.texturecoords[_tileID * 3 .. (_tileID + 1) * 3];
		_colorTexturecoords = _planet.icoSphere.texturecoordOffsets[_tileID * 3 .. (_tileID + 1) * 3];

		neighbours = getNeighbours();

		setColor(_biome.calculateColor());
	}

	/* Called periodicly, not every frame. time is in milliseconds and is the time since the last call of this function 
		Update the biome*/
	void updateBiome(long time) {
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
			_newBiome.biomeType = maxPressureID;
			_newBiome.biomeStrengthRef *= -1.0f;
		} else if(_newBiome.biomeStrength > Biome.Max_Strenght)
			_newBiome.biomeStrengthRef = Biome.Max_Strenght;

		setColor(_newBiome.calculateColor());
	}

	void update(float time) {
		_biome = _newBiome;
	}

	void setColor(Color color) nothrow {
		_planet.texture.changePixels(_colorTexturecoords[0],
								  _colorTexturecoords[1],
								  _colorTexturecoords[2],
								  color);
		_groundColor = color;
	}

	/// Return the vertices in common between the two tiles
	vec3[3] commonVertices(size_t otherTile) @trusted nothrow @nogc {
		vec3[3] commonVertices = vec3(0);
		size_t index;

		foreach(v1; vertices) {
			foreach(v2; _planet.tiles[otherTile].vertices) {
				if(v1 == v2) {
					commonVertices[index++] = v1;
					break;
				}
			}
		}

		return commonVertices;
	}

	/// Find all tiles sharing atleast one vertex with given tile
	Tile*[12] getNeighbours() @trusted nothrow @nogc {
		Tile*[12] neighbours;
		neighbours[] = null;
		size_t index;

		if(tileID < 5) {
			// Place all tiles in first layer as neighbours
			foreach(t; 0 .. 5) {
				if(t == tileID) continue;
				neighbours[index++] = _planet.tiles + t;
			}

			size_t middleNeighbour = _planet.icoSphere.Tile_NeighbourDown(tileID); // Triangle just under it
			for(int i = -3; i <= 3; i++) {
				neighbours[index++] = _planet.tiles + _planet.icoSphere.Tile_ToLevel(middleNeighbour + i, 2);
			}
		} else if(tileID >= _planet.tileCount - 5) {
			// Place all tiles in last layer as neighbours
			size_t lastLayer = _planet.tileCount - 5;
			foreach(t; 0 .. 5) {
				if(t == tileID - lastLayer) continue;
				neighbours[index++] = _planet.tiles + (lastLayer + t);
			}

			size_t middleNeighbour = _planet.icoSphere.Tile_NeighbourUp(tileID); // Triangle just above it
			for(int i = -3; i <= 3; i++) {
				neighbours[index++] = _planet.tiles + _planet.icoSphere.Tile_ToLevel(middleNeighbour + i, _planet.icoSphere.levelCount - 1 );
			}
		} else {
			/// Returns number of vertices shared by tiles
			size_t pointsShared(size_t tileID, size_t neighbourID) @trusted nothrow @nogc {
				size_t count;

				foreach(v1; _planet.icoSphere.positions[tileID * 3 .. (tileID + 1) * 3]) {
					foreach(v2; _planet.icoSphere.positions[neighbourID * 3 .. (neighbourID + 1) * 3]) {
						if(v1 == v2) count++;
					}
				}

				return count;
			}

			void put(size_t tile) @trusted nothrow @nogc {
				neighbours[index++] = _planet.tiles + tile;
			}

			size_t levelID = _planet.icoSphere.Tile_Level(tileID);

			// Check left tiles
			foreach(i; -4 .. 5) {
				if(i && pointsShared(tileID, _planet.icoSphere.Tile_ToLevel(tileID + i, levelID))) {
					put(_planet.icoSphere.Tile_ToLevel(tileID + i, levelID));
				}
			}

			// Check above tiles
			size_t currentTile = _planet.icoSphere.Tile_NeighbourUp(tileID);

			foreach(i; -3 .. 4) {
				if(pointsShared(tileID, _planet.icoSphere.Tile_ToLevel(currentTile + i, levelID - 1))) {
					put(_planet.icoSphere.Tile_ToLevel(currentTile + i, levelID - 1));
				}
			}

			// Check downard tiles
			currentTile = _planet.icoSphere.Tile_NeighbourDown(tileID);

			foreach(i; -3 .. 4) {
				if(pointsShared(tileID, _planet.icoSphere.Tile_ToLevel(currentTile + i, levelID + 1))) {
					put(_planet.icoSphere.Tile_ToLevel(currentTile + i, levelID + 1));
				}
			}
		}

		return neighbours;
	}

	~this() {

	}
}