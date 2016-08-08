module isolated.graphics.texture;

import std.typecons;

import isolated.graphics.utils.opengl;
import isolated.graphics.utils.framebuffer;
import isolated.file;
import isolated.graphics.shader;

import imageformats;
import isolated.utils.assets;
import isolated.utils.logger;
import isolated.graphics.vertexattribute;

import std.conv;
import std.range;
import std.array;

import isolated.math;

alias TextureManager = ResourceManager!(Texture, __loadTexture, __freeTexture, "isolated.graphics.texture");
alias TextureType = TextureManager.Handle;

struct Texture
{
	enum Mode {LOADED = 0, R = 1, RGB = 3, RGBA = 4};

	union {
		string name;
		ubyte[] pixels;
	}

	int width, height;
	GLuint id;
	Mode mode;

	alias TextureManager.get load;

	private this(string name, int width, int height) {
		this.name = name;
		this.width = width;
		this.height = height;
	}

	this(int width, int height, uint mode = GL_RGBA) {
		glGenTextures(1, &id);
		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		this.width = width;
		this.height = height;

		switch(mode) {
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

		this.pixels = new ubyte[width * height * cast(uint)this.mode];
		this.pixels[0..$] = 255;

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, mode, GL_UNSIGNED_BYTE, cast(void *)pixels.ptr);

		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void bind(int level = 0) {
		if(_triangleBufferCount) PixelChangeFlush();

		glActiveTexture(GL_TEXTURE0 + level);
		glBindTexture(GL_TEXTURE_2D, id);
	}

	void unbind() const {
		glBindTexture(GL_TEXTURE_2D, 0);
		glActiveTexture(GL_TEXTURE0);
	}

	void changePixel(int x, int y, VColor color) in {assert(mode != Mode.LOADED);}
	body {
		if(mode == Mode.RGBA) {
			pixels[(x + y * width) * 4] = color.r;
			pixels[(x + y * width) * 4 + 1] = color.g;
			pixels[(x + y * width) * 4 + 2] = color.b;
			pixels[(x + y * width) * 4 + 3] = color.a;
			glTextureSubImage2D(id, 0, x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, &pixels[(x + y * width) * 4]);
		} else if(mode == Mode.RGB) {
			pixels[(x + y * width) * 3] = color.r;
			pixels[(x + y * width) * 3 + 1] = color.g;
			pixels[(x + y * width) * 3 + 2] = color.b;
			glTextureSubImage2D(id, 0, x, y, 1, 1, GL_RGB, GL_UNSIGNED_BYTE, &pixels[(x + y * width) * 3]);
		} else if(mode == Mode.R) {
			pixels[x + y * width] = color.r;
			glTextureSubImage2D(id, 0, x, y, 1, 1, GL_RED, GL_UNSIGNED_BYTE, &pixels[x + y * width]);
		}
	}

	/* Drawing to a texture ( for multiple pixels, draws only triangles ) */
	private bool _isDirty = false;
	private FrameBuffer* _frameBuffer = null;

	private enum Triangle_Buffer_Size = 3;
	private vec2[Triangle_Buffer_Size * 3] _triangleBuffer;
	private VColor[Triangle_Buffer_Size] _color;
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
	void changePixels(vec2 v1, vec2 v2, vec2 v3, VColor color) nothrow in {assert(mode != Mode.LOADED);}
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
		/*Logger.info("PIXELS");
		Logger.info(_triangleBuffer[_triangleBufferCount * 3]);
		Logger.info(_triangleBuffer[_triangleBufferCount * 3 + 1]);
		Logger.info(_triangleBuffer[_triangleBufferCount * 3 + 2]);*/

		_color[_triangleBufferCount] = color;
		_triangleBufferCount++;
	}

	void PixelChangeFlush() nothrow {
		if(_triangleBufferCount == 0) return;

		checkError();

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

		checkError();
	}
}

Texture __loadTexture(string filename) {
	Logger.info("Loading texture : " ~ filename);

	auto texturefile = internal(filename);
	
	ubyte[] data = new ubyte[cast(uint) texturefile.size];
	texturefile.rawRead(data);
	texturefile.close();
	
	IFImage image = read_image_from_mem(data);
	
	Texture texture = Texture(filename, cast(int)image.w, cast(int)image.h);

	ubyte[] pixels = new ubyte[image.pixels.length];
	size_t width = cast(size_t) (image.pixels.length / image.h);
	foreach(i; 0..texture.height - 1) {
		pixels[width * i .. width * (i + 1)] = image.pixels[width * (texture.height - 2 - i) .. width * (texture.height - 1 - i)];
	}
	
	glGenTextures(1, &texture.id);
	glBindTexture(GL_TEXTURE_2D, texture.id);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture.width, texture.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void *)pixels);
	
	glBindTexture(GL_TEXTURE_2D, 0);
	
	checkError();

	texture.mode = Texture.Mode.LOADED;

	return texture;
}

void __freeTexture(Texture texture) {
	Logger.info("Freeing texture : ");
	Logger.info(texture.name);
	glDeleteTextures(1, &texture.id);
}