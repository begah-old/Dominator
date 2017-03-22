module isolated.gui.font;

import shared_memory;

import derelict.freetype.ft;

import isolated.math;
import isolated.file;
import isolated.utils.logger;
import isolated.graphics.texture;
import isolated.graphics.utils.opengl;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;
import isolated.graphics.shader;

private FT_Library library;

private derelict.util.exception.ShouldThrow missingSymFunc( string symName ) {
    import std.algorithm : equal;
    static import derelict.util.exception;
    foreach(s; ["FT_New_Memory_Face", "FT_Attach_File", "FT_Set_Pixel_Sizes", 
	"FT_Get_Char_Index", "FT_Load_Char", "FT_Done_Face", 
	"FT_Init_FreeType", "FT_Done_FreeType"]) {
        if (symName.equal(s)) // Symbol is used
            return derelict.util.exception.ShouldThrow.Yes;
    }
    // Don't throw for unused symbol
    return derelict.util.exception.ShouldThrow.No;
}

shared static this() {
	// Load the FreeType library.
	DerelictFT.missingSymbolCallback = &missingSymFunc;
    DerelictFT.load();

	cast(void)FT_Init_FreeType(&library);
}

class FontManager {
	static __gshared FontManager current;

	string fontname;

	Font _25, _50, _100;

	this(string fontname) {
		File fontFile = internal("Fonts/" ~ fontname ~ ".ttf");
		ubyte[] data = new ubyte[cast(uint) fontFile.size];
		fontFile.rawRead(data);
		fontFile.close();

		FT_Face face;
		FT_Error error = FT_New_Memory_Face(library, data.ptr, cast(int)(data.length * ubyte.sizeof), 0, &face);

		assert(!error, "Failed to load font : " ~ fontname);

		_25 = new Font(fontname, face, 25);
		_50 = new Font(fontname, face, 50);
		_100 = new Font(fontname, face, 100);

		FT_Done_Face(face);
		FT_Done_FreeType(library);

		current = this;
	}

	static void use(FontManager manager) {
		this.current = manager;
	}

	Mesh renderText(string text, int maxWidth, int availableHeight, out vec2i size) {
		if(availableHeight <= 30) {
			return _25.renderText(text, maxWidth, size);
		} else if(availableHeight <= 75) {
			return _50.renderText(text, maxWidth, size);
		} else {
			return _100.renderText(text, maxWidth, size);
		}
	}

	vec2i dimensionText(string text, int availableHeight) {
		if(availableHeight <= 30) {
			return _25.dimensionText(text);
		} else if(availableHeight <= 75) {
			return _50.dimensionText(text);
		} else {
			return _100.dimensionText(text);
		}
	}

	Font getFont(int availableHeight) {
		if(availableHeight <= 30) {
			return _25;
		} else if(availableHeight <= 75) {
			return _50;
		} else {
			return _100;
		}
	}
}

class Font {
	string fontname;

	Texture atlas;

	int fontSize;

	struct Character_Info {
		vec4 textureCoordinates; // downard left corner (xy) and upper right corner (zw)
		int width, height;
		vec2i bearing;
		long advance;
	}

	Character_Info[char] characters;
	int textHeight;
	int textMinY, textMaxY;

	static __gshared Shader shader;
	static __gshared int count;

	this(string fontname) {
		File fontFile = internal("Fonts/" ~ fontname ~ ".ttf");
		ubyte[] data = new ubyte[cast(uint) fontFile.size];
		fontFile.rawRead(data);
		fontFile.close();
		this.fontname = fontname;

		FT_Face face;
		FT_Error error = FT_New_Memory_Face(library, data.ptr, cast(int)(data.length * ubyte.sizeof), 0, &face);

		assert(!error, "Failed to load font : " ~ fontname);

		this(fontname, face, 100);

		FT_Done_Face(face);
		FT_Done_FreeType(library);
	}

	private this(string fontname, FT_Face face, int size) {
		if(!count) {
			// Load font shader
			Logger.info("Loading font shader");
			shader = new Shader("font");
		}

		assert(!FT_Set_Pixel_Sizes(face,    /* handle to face object */
								   0,        /* pixel_width           */
								   size), "Failed to set pixel size for font " ~ fontname);  /* pixel_height */

		int fullWidth = 1, fullHeight;
		FT_GlyphSlot glyph = face.glyph;

		foreach(char c; 32 .. 128) {
			assert(!FT_Load_Char(face, c, FT_LOAD_RENDER), "Failed to load charater : " ~ c ~ " in font file " ~ fontname);
			if(c > 32) fullWidth += glyph.bitmap.width + 1;
			if(c > 32) fullHeight = fullHeight > glyph.bitmap.rows ? fullHeight : glyph.bitmap.rows;
		}

		assert(fullWidth > 1, "Hum atlas width is " ~ fullWidth.to!string ~ ", please report this bug to Avatar Wan, only he can help you now");

		atlas = new Texture(fullWidth, fullHeight, GL_RED, false);
		atlas.clear(Color(0));

		int x = 1;
		textMinY = int.max;
		textMaxY = int.min;
		char min, max;

		foreach(char c; 32 .. 128) {
			assert(!FT_Load_Char(face, c, FT_LOAD_RENDER), "Failed second time to load charater : " ~ c ~ " in font file " ~ fontname);
			if(c > 32) atlas.changeSquare(vec2i(x, 0), vec2i(glyph.bitmap.width, glyph.bitmap.rows), (cast(ubyte*)glyph.bitmap.buffer)[0 .. glyph.bitmap.width * glyph.bitmap.rows], false, true);
			characters[c] = Character_Info(vec4(x / cast(float)fullWidth, 0, (x + glyph.bitmap.width) / cast(float)fullWidth, glyph.bitmap.rows / cast(float)fullHeight), glyph.bitmap.width, glyph.bitmap.rows, vec2i(glyph.bitmap_left, glyph.bitmap_top), glyph.advance.x >> 6);
			if(c > 32) {
				if(cast(int)glyph.bitmap_top - cast(int)glyph.bitmap.rows < textMinY) {
					textMinY = glyph.bitmap_top - glyph.bitmap.rows; min = c; }
				if(glyph.bitmap_top > textMaxY) { textMaxY = glyph.bitmap_top; max = c; }
				x += glyph.bitmap.width + 1;
			}
		}

		textHeight = textMaxY - textMinY;

		atlas.generate();
		count++;
	}

	Mesh renderText(string text, int maxWidth, out vec2i size) {
		Mesh mesh = new Mesh();
		vec3[] position;
		vec2[] texturecoord;
		position.length = texturecoord.length = text.length * 6;
		int x;

		foreach(i, c; text) {
			if(c == ' ') {
				x += characters[' '].advance;
				if(maxWidth > 0 && x > maxWidth) break;
				continue;
			} else if(c == '\t') {
				x += characters[' '].advance * 2;
			}

			Character_Info ci = characters[c];

			if(i == 0) x = -ci.bearing.x;

			float x1 = (x + ci.bearing.x) / cast(float)mainWindow.width * 2.0f, x2 = x1 + cast(float)ci.width / mainWindow.width * 2.0f;
			float y1 = (ci.bearing.y - ci.height) / cast(float)mainWindow.height * 2.0f, y2 = y1 + cast(float)ci.height / mainWindow.height * 2.0f;

			if(maxWidth > 0 && x + ci.width + ci.bearing.x > maxWidth) {
				position[i * 6] = vec3(x1, y1, 0); texturecoord[i * 6] = ci.textureCoordinates.xy;
				float originalWidth = ci.width, newWidth = maxWidth - x;
				float xx2 = x1 + cast(float)newWidth / mainWindow.width * 2.0f;
				float percantageOfOriginalWidth = newWidth / originalWidth;
				float newZ = ci.textureCoordinates.x + (ci.textureCoordinates.z - ci.textureCoordinates.x) * percantageOfOriginalWidth;
				position[i * 6 + 1] = vec3(xx2, y2, 0); texturecoord[i * 6 + 1] = vec2(newZ, ci.textureCoordinates.w);
				position[i * 6 + 2] = vec3(x1, y2, 0); texturecoord[i * 6 + 2] = ci.textureCoordinates.xw;
				position[i * 6 + 3] = vec3(x1, y1, 0); texturecoord[i * 6 + 3] = ci.textureCoordinates.xy;
				position[i * 6 + 4] = vec3(xx2, y1, 0); texturecoord[i * 6 + 4] = vec2(newZ, ci.textureCoordinates.y);
				position[i * 6 + 5] = vec3(xx2, y2, 0); texturecoord[i * 6 + 5] = vec2(newZ, ci.textureCoordinates.w);
				position.length = texturecoord.length = (i + 1) * 6;
				break;
			}

			position[i * 6] = vec3(x1, y1, 0); texturecoord[i * 6] = ci.textureCoordinates.xy;
			position[i * 6 + 1] = vec3(x2, y2, 0); texturecoord[i * 6 + 1] = ci.textureCoordinates.zw;
			position[i * 6 + 2] = vec3(x1, y2, 0); texturecoord[i * 6 + 2] = ci.textureCoordinates.xw;
			position[i * 6 + 3] = vec3(x1, y1, 0); texturecoord[i * 6 + 3] = ci.textureCoordinates.xy;
			position[i * 6 + 4] = vec3(x2, y1, 0); texturecoord[i * 6 + 4] = ci.textureCoordinates.zy;
			position[i * 6 + 5] = vec3(x2, y2, 0); texturecoord[i * 6 + 5] = ci.textureCoordinates.zw;

			if(i + 1 != text.length) x += ci.advance;
			else x += ci.width + ci.bearing.x;
		}

		size = vec2i(x, textHeight);

		float halfX = cast(float)size.x / mainWindow.width, halfY = cast(float)size.y / mainWindow.height;

		foreach(ref v; position) {
			v.x -= halfX;
			v.y -= textMinY / cast(float)mainWindow.height * 2.0f + halfY;
		}

		mesh.add(VertexAttribute.Position.set(cast(float[])position));
		mesh.add(VertexAttribute.TexCoords.set(cast(float[])texturecoord));

		mesh.generate(shader);

		return mesh;
	}

	vec2i dimensionText(string text) {
		int x;

		foreach(i, c; text) {
			if(c == ' ') {
				x += characters[' '].advance;
				continue;
			} else if(c == '\t') {
				x += characters[' '].advance * 2;
			}

			Character_Info ci = characters[c];

			if(i == 0) x = -ci.bearing.x;

			if(i + 1 != text.length) x += ci.advance;
			else x += ci.width + ci.bearing.x;
		}

		return vec2i(x, textHeight);
	}

	~this() {
		count--;
	}
	
}