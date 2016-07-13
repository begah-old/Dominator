module isolated.graphics.texture;

import std.typecons;

import isolated.graphics.utils.opengl;
import isolated.file;

import imageformats;
import isolated.utils.assets;
import isolated.utils.logger;
import std.conv;

alias TextureManager = ResourceManager!(Texture, __loadTexture, __freeTexture, "isolated.graphics.texture");
alias TextureType = TextureManager.Handle;

struct Texture
{
	string name = null;
	int width, height;
	GLuint id;

	alias TextureManager.get load;

	void bind(int level = 0) const {
		glActiveTexture(GL_TEXTURE0 + level);
		glBindTexture(GL_TEXTURE_2D, id);
	}

	void unbind() const {
		glBindTexture(GL_TEXTURE_2D, 0);
		glActiveTexture(GL_TEXTURE0);
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
	
	return texture;
}

void __freeTexture(Texture texture) {
	Logger.info("Freeing texture : ");
	Logger.info(texture.name);
	glDeleteTextures(1, &texture.id);
}