module isolated.math.icosphere;

import std.conv : to;
import std.algorithm;

import isolated.math;
import isolated.math.icosphere_data;

import isolated.utils.logger;

class IcoSphere {
	int subdivisionLevel, /* Number of subdivion the sphere has ( only 3, 4 and 5 are supported ) */
		levelCount, /* Number of level the sphere has, depends on the subdivisionLevel */
		levelMaxSize /* First level to have max size, depends on the subdivisionLevel */;

	private vec2[] _intervals; /* Height intervals to determine on which level a triangle resides */

	private vec3[] _positions, _normals; /* Actual position and normal of the sphere in order */
	ref vec3[] positions() @property @safe @nogc nothrow {return this._positions;}
	ref vec3[] normals() @property @safe @nogc nothrow {return this._normals;}

	private vec2[] _texturecoords; /* Actual texture coordinates of the sphere in order */
	ref vec2[] texturecoords() @property @safe @nogc nothrow {return this._texturecoords;}

	private vec2i[] _texturecoord_offsets; /* Offset needed to render more than enough pixels for a full colored triangle expressed in pixels */
	ref vec2i[] texturecoordOffsets() @property @safe @nogc nothrow {return this._texturecoord_offsets;}

	private immutable int[] _levelIndeces; /* Place ( in triangles ) the level is in memory */

	this(int subdivisionLevel) {
		this.subdivisionLevel = subdivisionLevel;
		if(subdivisionLevel == 3) {
			this.levelCount = 12;
			this.levelMaxSize = 5;
			_intervals = [vec2(0, 0.25f), vec2(0.27f, 0.5f), vec2(0.52f, 0.72f), vec2(0.73f, 0.89f), vec2(0.9f, 0.96f), vec2(0.97f, 1.0f)];
			_levelIndeces = IcoSphere3_LevelIndeces;
			construct(IcoSphere3_Positions, IcoSphere3_Normals, IcoSphere3_TextCoords, IcoSphere3_TextCoords_Offset);
		} else if(subdivisionLevel == 4) {
			this.levelCount = 24;
			this.levelMaxSize = 9;
			_intervals = [vec2(0.0f, 0.1f), vec2(0.17f, 0.24f), vec2(0.28f, 0.37f), vec2(0.38f, 0.49f), vec2(0.49f, 0.596f), vec2(0.598f, 0.7f), vec2(0.7f, 0.8f), vec2(0.8f, 0.87f), vec2(0.88f, 0.93f), vec2(0.93f, 0.97f), vec2(0.97f, 0.99f), vec2(0.99f, 1.0f)];
			_levelIndeces = IcoSphere4_LevelIndeces;
			construct(IcoSphere4_Positions, IcoSphere4_Normals, IcoSphere4_TextCoords, IcoSphere4_TextCoords_Offset);
		} else if(subdivisionLevel == 5) {
			this.levelCount = 48;
			this.levelMaxSize = 17;
			_intervals = [vec2(0.0f, 0.05f), vec2(0.08f, 0.12f), vec2(0.15f, 0.19f), vec2(0.2f, 0.26f), vec2(0.27f, 0.324125f), vec2(0.324125f, 0.382f), vec2(0.386f, 0.44f), vec2(0.44f, 0.492f), vec2(0.497f, 0.546099f), vec2(0.546099f, 0.6f), vec2(0.6f, 0.653169f), vec2(0.653169f, 0.701903f), vec2(0.701903f, 0.753809f),
				vec2(0.753809f, 0.801878f), vec2(0.801878f, 0.844915f), vec2(0.844915f, 0.8763f), vec2(0.8763f, 0.909918f), vec2(0.909918f, 0.934339f), vec2(0.934339f, 0.95788f), vec2(0.95788f, 0.972845f), vec2(0.972845f, 0.98495f), vec2(0.98495f, 0.992089f), vec2(0.992089f, 0.997323f), vec2(0.997323f, 1.0f)];
			_levelIndeces = IcoSphere5_LevelIndeces;
			construct(IcoSphere5_Positions, IcoSphere5_Normals, IcoSphere5_TextCoords, IcoSphere5_TextCoords_Offset);
		} else assert("Such icoSphere is not supported : " ~ to!string(subdivisionLevel) ~ " (subdivisionLevel)");
	}

	private void construct(immutable vec3[] pos, immutable vec3[] norms, immutable vec2[] textcoords, immutable vec2i[] textcoord_offsets) {
		_positions = new vec3[pos.length * 2];
		_normals = new vec3[norms.length * 2];
		_texturecoords = new vec2[textcoords.length * 2];
		_texturecoord_offsets = new vec2i[textcoord_offsets.length * 2];

		_positions[0..pos.length] = pos;
		_normals[0..norms.length] = norms;
		_texturecoords[0..textcoords.length] = textcoords;
		_texturecoord_offsets[0..textcoord_offsets.length] = textcoord_offsets;
		_texturecoord_offsets[textcoord_offsets.length .. textcoord_offsets.length * 2] = textcoord_offsets;

		int index = pos.length;
		
		foreach_reverse(i; 1..this.levelCount / 2 +1) {
			int ind = this.getLevelIndex(i) * 3;
			int size = this.getLevelSize(i) * 3;

			_positions[index .. index + size] = pos[ind .. ind + size];
			_normals[index .. index + size] = norms[ind .. ind + size];
			_texturecoords[index .. index + size] = textcoords[ind .. ind + size];

			index += size;
		}

		foreach(i; pos.length .. pos.length * 2) {
			_positions[i].y = -_positions[i].y;
			_normals[i].y = -_normals[i].y;
			_texturecoords[i].y -= 0.5f;
		}
	}

	/* Calculate where the triangle is in memory ( not the vertices, multiply by 3 to use in texturecoords or positions ) */
	size_t triangleIndex(vec3 v1, vec3 v2, vec3 v3) @safe nothrow @nogc {
		vec3 middle = (v1 + v2 + v3) / 3.0f;

		foreach(i, interval; _intervals) {
			if(middle.y >= interval.x && middle.y <= interval.y) {
				int index = this.levelCount - i;

				return getLevelIndex(index);
			}
		}

		return 0;
	}

	size_t getLevelIndex(int level) @safe nothrow @nogc in {assert(level > 0 && level <= this.levelCount);}
	body {
		return _levelIndeces[level - 1];
	}

	int getLevelSize(int level) @safe nothrow @nogc in {assert(level > 0 && level <= this.levelCount);}
	body {
		if(level > this.levelCount / 2) {
			return getLevelSize(this.levelCount - level + 1);
		} else if(level >= this.levelMaxSize) {
			return pow(2, (this.subdivisionLevel - 3)) * 40;
		} else return 5 * ( 2 * level - 1);
	}

	@trusted nothrow @nogc :

	/// Calculate which level the tile resides in
	int Tile_Level(size_t tileID) {
		int currLevel = levelCount / 2;
		int size = currLevel;

		while(true) {
			size_t levelIndex = getLevelIndex(currLevel);
			size_t levelSize = getLevelSize(currLevel);

			if(tileID >= levelIndex && tileID < levelIndex + levelSize) {
				return currLevel;
			} else if(tileID < levelIndex) {
				currLevel -= size / 2;
				size = cast(int)ceil(size / 2.0);
			} else {
				currLevel += cast(int)ceil(size / 2.0);
				size = cast(int)ceil(size / 2.0);
			}
		}
	}

	/// Makes sure tileID is within level, if not figures out the best possible position of tile in level
	size_t Tile_ToLevel(size_t tileID, int levelID) in { assert(levelID > 0 && levelID <= levelCount); } out(result) { assert(result >= 0 && result < _positions.length / 3, "Tile_ToLevel : Tile id returned is wrong"); }
	body {
		if(*(cast(sizediff_t*)&tileID) < 0) {
			sizediff_t t2 = *(cast(sizediff_t*)&tileID);
			t2 += 5;
			return *(cast(size_t*)&t2);
		}

		int levelSize = getLevelSize(levelID);
		size_t levelIndex = getLevelIndex(levelID);

		if(tileID < levelIndex) return tileID + levelSize;
		else if(tileID >= levelIndex + levelSize) return tileID - levelSize;
		else return tileID;
	}

	/// Find tile just to the left of given tile ( tile + 1 )
	size_t Tile_NeighbourLeft(size_t tileID) {
		return Tile_ToLevel(tileID + 1, Tile_Level(tileID));
	}

	/// Find tile just to the right of given tile ( tile - 1 )
	size_t Tile_NeighbourRight(size_t tileID) {
		return Tile_ToLevel(tileID - 1, Tile_Level(tileID));
	}

	/// Find tile just below given tile
	size_t Tile_NeighbourDown(size_t tileID) {
		int level = Tile_Level(tileID);

		int levelSize = getLevelSize(level);
		size_t levelIndex = getLevelIndex(level);
		int downLevelSize = getLevelSize(level + 1);

		if(levelSize == downLevelSize) {
			return tileID + levelSize;
		} else if(levelSize < downLevelSize) {
			int levelSideCount = levelSize / 5; // Tiles count per side
			int numCorners = ( tileID - levelIndex + (levelSideCount / 2) ) / levelSideCount; // Number of corners between first tile and this tile

			size_t newIndex = tileID + levelSize + numCorners * ( (downLevelSize - levelSize) / 5 ); // (downLevelSize - levelSize) / 5 : Calculate how many tiles each corner has ( usually 2 but sometimes 1 )

			return Tile_ToLevel(newIndex, level + 1);
		} else { // Current level is bigger than downard level
			int levelSideCount = levelSize / 5; // Tiles count per side
			int numCorners = ( tileID - levelIndex + ((levelSideCount - 1) / 2) ) / levelSideCount; // Number of corners between first tile and this tile
			size_t newIndex = (levelIndex + levelSize) + (tileID - levelIndex) - numCorners * ( (levelSize - downLevelSize) / 5 );

			return Tile_ToLevel(newIndex, level + 1);
		}
	}

	/// Find tile just above given tile
	size_t Tile_NeighbourUp(size_t tileID) {
		int level = Tile_Level(tileID);

		int levelSize = getLevelSize(level);
		size_t levelIndex = getLevelIndex(level);
		int upLevelSize = getLevelSize(level - 1);
		size_t upLevelIndex = levelIndex - upLevelSize;

		int levelSideCount, numCorners;
		size_t newIndex;

		if(levelSize == upLevelSize) {
			return tileID - levelSize;
		} else if(levelSize > upLevelSize) {
			levelSideCount = levelSize / 5; // Tiles count per side
			numCorners = ( tileID - levelIndex + ((levelSideCount - 1) / 2) ) / levelSideCount; // Number of corners between first tile and this tile
			newIndex = upLevelIndex + (tileID - levelIndex) - numCorners * ( (levelSize - upLevelSize) / 5 );

			return Tile_ToLevel(newIndex, level - 1);
		} else { // Upper level is bigger than level
			levelSideCount = levelSize / 5; // Tiles count per side
			numCorners = ( tileID - levelIndex + ((levelSideCount - 1) / 2) ) / levelSideCount; // Number of corners between first tile and this tile
			newIndex = tileID - upLevelSize + numCorners * ( (upLevelSize - levelSize) / 5 );

			return Tile_ToLevel(newIndex, level - 1);
		}
	}
}