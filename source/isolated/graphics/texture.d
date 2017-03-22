module isolated.graphics.texture;

import std.typecons;

import isolated.graphics.utils.opengl;
import isolated.graphics.utils.framebuffer;
import isolated.file;
import isolated.graphics.shader;

import imageformats;
import isolated.utils.logger;
import isolated.graphics.vertexattribute;

import std.conv;
import std.range;
import std.array;

import isolated.math;

class Texture
{
	enum Mode {LOADED = 0, R = 1, RGB = 3, RGBA = 4, DEPTH = 5};

	union {
		string name;
		ubyte[] pixels;
	}

	int width, height;
	GLuint id;
	Mode mode;
	uint glMode;

	alias load = __loadTexture;

	private static Mode glModeToEnum(uint mode) {
		switch(mode) {
			case GL_RED:
				return Mode.R;
			case GL_RGB:
				return Mode.RGB;
			case GL_RGBA:
				return Mode.RGBA;
			default: return Mode.LOADED;
		}
	}

	private this(string name, int width, int height) {
		this.name = name;
		this.width = width;
		this.height = height;

		this.mode = Mode.LOADED;
	}

	this(int width, int height, uint mode = GL_RGBA, bool generate = true) {
		glGenTextures(1, &id);
		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

		this.width = width;
		this.height = height;
		glMode = mode;
		this.mode = glModeToEnum(mode);

		this.pixels = new ubyte[width * height * cast(uint)this.mode];
		this.pixels[0..$] = 255;

		if(generate) glTexImage2D(GL_TEXTURE_2D, 0, glMode, width, height, 0, glMode, GL_UNSIGNED_BYTE, cast(void *)pixels.ptr);

		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void bind(size_t level = 0) {
		//if(_isDirty) PixelChangeFlush();

		glActiveTexture(GL_TEXTURE0 + cast(GLint)level);
		glBindTexture(GL_TEXTURE_2D, id);
	}

	void unbind() const {
		glBindTexture(GL_TEXTURE_2D, 0);
		glActiveTexture(GL_TEXTURE0);
	}

	void generate() {
		glBindTexture(GL_TEXTURE_2D, id);
		glTexImage2D(GL_TEXTURE_2D, 0, glMode, width, height, 0, glMode, GL_UNSIGNED_BYTE, cast(void *)pixels.ptr);

		switch(glMode) {
			case GL_RED:
				this.mode = Mode.R;
				break;
			case GL_RGB:
				this.mode = Mode.RGB;
				break;
			case GL_RGBA:
				this.mode = Mode.RGBA;
				break;
			default: assert(0);
		}
	}

	static Texture generateDepthTexture(int width, int height) {
		Texture texture = new Texture(null, width, height);
		texture.mode = Mode.DEPTH;

		// create a depth texture
		glGenTextures(1, &texture.id);
		glBindTexture(GL_TEXTURE_2D, texture.id);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, width, height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		glBindTexture(GL_TEXTURE_2D, 0);

		return texture;
	}

	static Texture generateColorTexture(int width, int height, uint mode = GL_RGBA) {
		Texture texture = new Texture(null, width, height);
		texture.mode = glModeToEnum(mode);

		// create a color texture
		glGenTextures(1, &texture.id);
		glBindTexture(GL_TEXTURE_2D, texture.id);
		glTexImage2D(GL_TEXTURE_2D, 0, mode, width, height, 0, mode, GL_UNSIGNED_BYTE, null);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		glBindTexture(GL_TEXTURE_2D, 0);

		return texture;
	}

	void clear(Color color) {
		if(mode == Mode.R) {
			pixels[0 .. $] = color.r;
		} else if(mode == Mode.RGB) {
			foreach(i; 0 .. pixels.length / 3) {
				pixels[i * 3] = color.r;
				pixels[i * 3 + 1] = color.g;
				pixels[i * 3 + 2] = color.b;
			}
		} else if(mode == Mode.RGBA) {
			foreach(i; 0 .. pixels.length / 4) {
				pixels[i * 4] = color.r;
				pixels[i * 4 + 1] = color.g;
				pixels[i * 4 + 2] = color.b;
				pixels[i * 4 + 3] = color.a;
			}
		}

		if(id != 0) {
			glBindTexture(GL_TEXTURE_2D, id);
			glTexImage2D(GL_TEXTURE_2D, 0, glMode, width, height, 0, glMode, GL_UNSIGNED_BYTE, cast(void *)pixels.ptr);
		}
	}

	void changePixel(int x, int y, Color color) in {assert(mode != Mode.LOADED);}
	body {
		if(mode == Mode.RGBA) {
			pixels[(x + y * width) * 4] = color.r;
			pixels[(x + y * width) * 4 + 1] = color.g;
			pixels[(x + y * width) * 4 + 2] = color.b;
			pixels[(x + y * width) * 4 + 3] = color.a;
			if(id != 0) glTextureSubImage2D(id, 0, x, y, 1, 1, glMode, GL_UNSIGNED_BYTE, &pixels[(x + y * width) * 4]);
		} else if(mode == Mode.RGB) {
			pixels[(x + y * width) * 3] = color.r;
			pixels[(x + y * width) * 3 + 1] = color.g;
			pixels[(x + y * width) * 3 + 2] = color.b;
			if(id != 0) glTextureSubImage2D(id, 0, x, y, 1, 1, glMode, GL_UNSIGNED_BYTE, &pixels[(x + y * width) * 3]);
		} else if(mode == Mode.R) {
			pixels[x + y * width] = color.r;
			if(id != 0) glTextureSubImage2D(id, 0, x, y, 1, 1, glMode, GL_UNSIGNED_BYTE, &pixels[x + y * width]);
		}
	}

	void changeSquare(vec2i bottom, vec2i size, ubyte[] color, bool reverseX = false, bool reverseY = false) in {assert(mode != Mode.LOADED); assert(size.x * size.y * mode == color.length, "Need to provide enough color elements to fill a " ~ to!string(size.x) ~ " and " ~ to!string(size.y) ~ " square of pixels");}
	body {
		if(size.x == 0 || size.y == 0) return;

		glBindTexture(GL_TEXTURE_2D, id);
		foreach(y; 0 .. size.y) {
			foreach(x; 0 .. size.x) {
				int colorx, colory;
				if(reverseY) {
					colory = (size.y - 1 - y);
				}
				else {
					colory = y;
				}
				if(reverseX) {
					colorx = (size.x - 1 - x);
				} else {
					colorx = x;
				}

				if(mode == Mode.RGBA) {
					pixels[(x + bottom.x + (y + bottom.y) * width) * 4 .. (x + bottom.x + (y + bottom.y) * width + 1) * 4] = color[(colorx + colory * size.x) * 4 + (colorx + colory * size.x + 1) * 4];
				} else if(mode == Mode.RGB) {
					pixels[(x + bottom.x + (y + bottom.y) * width) * 3 .. (x + bottom.x + (y + bottom.y) * width + 1) * 3] = color[(colorx + colory * size.x) * 3 + (colorx + colory * size.x + 1) * 3];
				} else if(mode == Mode.R) {
					pixels[x + bottom.x + (y + bottom.y) * width] = color[colorx + colory * size.x];
				}
			}
		}
		if(id != 0) glTexImage2D(GL_TEXTURE_2D, 0, glMode, width, height, 0, glMode, GL_UNSIGNED_BYTE, cast(void *)pixels.ptr);
		//glTextureSubImage2D(id, 0, 0, 0, width, height, glMode, GL_UNSIGNED_BYTE, pixels.ptr);
		checkError();
	}

	/* Drawing to a texture ( for multiple pixels, draws only triangles ) */
	private bool _isDirty = false;
	bool isDirty() @property @safe @nogc nothrow {return _isDirty;}
	private FrameBuffer* _frameBuffer = null;

	private enum Triangle_Buffer_Size = 500;
	private vec2[Triangle_Buffer_Size * 3] _triangleBuffer;
	private Color[Triangle_Buffer_Size] _color;
	private int _triangleBufferCount;

	private static Shader _framebufferShader = null;
	private GLuint _VAO, _VBO;
	private VertexAttribute _posAttribute;

	private void initPixelChange() nothrow {
		import core.stdc.stdlib : malloc;
		_frameBuffer = cast(FrameBuffer*)malloc(FrameBuffer.sizeof);

		*_frameBuffer = FrameBuffer(true);
		_frameBuffer.addTexture(id);
		_frameBuffer.setup();

		_frameBuffer.unbind();

		if(_framebufferShader is null) {
			_framebufferShader = Shader.fromSource(
				"#version 330 core\n"
				"in vec2 pos;\n"
				"void main() {\n"
				"	gl_Position = vec4(pos, 0.0, 1.0);\n"
				"}", 
				"#version 330 core\n"
				"uniform vec4 color;\n"
				"out vec4 FragColor;\n"
				"void main() {\n"
				"	FragColor = color;\n"
				"}");

			glGenVertexArrays(1, &_VAO);
			glBindVertexArray(_VAO);

			glGenBuffers(1, &_VBO);
			glBindBuffer(GL_ARRAY_BUFFER, _VBO);
			glBufferData(GL_ARRAY_BUFFER, Triangle_Buffer_Size * 6 * float.sizeof, _triangleBuffer.ptr, GL_DYNAMIC_DRAW);

			glEnableVertexAttribArray(0);
			glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, null);

			glBindVertexArray(0);
		}
	}
	
	/* Draws a triangle on the specific texture, vectors are in texture coordinates */
	void changePixels(vec2 v1, vec2 v2, vec2 v3, Color color) nothrow in {assert(mode != Mode.LOADED);}
	body {
		if(_isDirty == false) {
			_isDirty = true;
			if(_frameBuffer is null) {
				initPixelChange();
			}
		}
		if(_triangleBufferCount == Triangle_Buffer_Size) {
			PixelChangeFlush();
		}

		_triangleBuffer[_triangleBufferCount * 3] = (v1 * 2.0f) - vec2(1f);
		_triangleBuffer[_triangleBufferCount * 3 + 1] = (v2 * 2.0f) - vec2(1f);
		_triangleBuffer[_triangleBufferCount * 3 + 2] = (v3 * 2.0f) - vec2(1f);

		_color[_triangleBufferCount] = color;
		_triangleBufferCount++;
	}

	void PixelChangeFlush() nothrow {
		if(_triangleBufferCount == 0) return;

		checkError();

		glDisable(GL_DEPTH_TEST);

		_frameBuffer.bind(width, height);

		_framebufferShader.bind();

		glBindVertexArray(_VAO);

		glBindBuffer(GL_ARRAY_BUFFER, _VBO); // TODO: See if necessary as it is bound to VAO

		glBufferSubData(GL_ARRAY_BUFFER, 0, _triangleBufferCount * 6 * float.sizeof, _triangleBuffer.ptr);

		foreach(i; 0 .. _triangleBufferCount) {
			_framebufferShader.uniform("color", _color[i]);
			glDrawArrays(GL_TRIANGLES, i * 3, 3);
		}

		glBindVertexArray(0);

		_framebufferShader.unbind();

		_frameBuffer.unbind();

		_triangleBufferCount = 0;

		glEnable(GL_DEPTH_TEST);

		checkError();
	}

	~this() {
		Logger.info("Freeing texture : ");
		Logger.info(name);
		glDeleteTextures(1, &id);
	}
}

Texture __loadTexture(string filename) {
	Logger.info("Loading texture : " ~ filename);

	auto texturefile = internal(filename);
	
	ubyte[] data = new ubyte[cast(uint) texturefile.size];
	texturefile.rawRead(data);
	texturefile.close();
	
	IFImage image = read_image_from_mem(data);
	
	Texture texture = new Texture(filename, cast(int)image.w, cast(int)image.h);

	ubyte[] pixels = new ubyte[image.pixels.length];
	foreach(i; 0 .. cast(size_t)image.h) {
		pixels[cast(size_t)image.w * 4 * i .. cast(size_t)image.w * 4 * (i + 1)] = image.pixels[cast(size_t)image.w * 4 * (cast(size_t)image.h - 1 - i) .. cast(size_t)image.w * 4 * (cast(size_t)image.h - i)];
	}

	glGenTextures(1, &texture.id);
	glBindTexture(GL_TEXTURE_2D, texture.id);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture.width, texture.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void *)pixels);

	glBindTexture(GL_TEXTURE_2D, 0);
	
	checkError();

	return texture;
}

// Load a single image as imageCount many images
Texture[count] __loadTexture(int count)(string filename) {
	Logger.info("Loading textures : " ~ filename);

	auto texturefile = internal(filename);

	ubyte[] data = new ubyte[cast(uint) texturefile.size];
	texturefile.rawRead(data);
	texturefile.close();

	IFImage image = read_image_from_mem(data);

	Texture[count] textures;
	size_t width = cast(size_t)image.w / count;
	foreach(i; 0 .. count) {
		textures[i] = new Texture(filename, cast(int)width, cast(int)image.h);
	}

	ubyte[][] pixels = new ubyte[][](count, image.pixels.length);

	foreach(i; 0 .. cast(size_t)image.h) {
		foreach(x; 0 .. count) {
			pixels[x][width * 4 * i .. width * 4 * (i + 1)] = image.pixels[cast(size_t)image.w * 4 * (cast(size_t)image.h - 1 - i) + x * width * 4 .. cast(size_t)image.w * 4 * (cast(size_t)image.h - 1 - i) + (x + 1) * width * 4];
		}
	}

	foreach(i; 0 .. count) {
		glGenTextures(1, &textures[i].id);
		glBindTexture(GL_TEXTURE_2D, textures[i].id);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast(int)width, cast(int)image.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void *)pixels[i]);

		checkError();
	}

	return textures;
}