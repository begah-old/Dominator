module isolated.graphics.utils.framebuffer;

import isolated.graphics.utils.opengl;
import isolated.utils.logger;
import isolated.graphics.texture;

struct FrameBuffer {
	nothrow :

	private GLuint _buffer;
	private int texturesAttached;	
	private GLenum[] _drawBuffer;
	private GLint[4] old_viewport;

	private Texture[] textures;
	private Texture depth;

	@disable this();

	this(bool _init) {
		if(_init)
			init();
	}

	void init() {
		checkError();
		glGenFramebuffers(1, &_buffer);
		checkError();
	}

	Texture addTexture(Texture texture, bool depth = false) {
		addTexture(texture.id, depth);
		if(!depth) textures ~= texture;
		else this.depth = texture;

		return texture;
	}

	uint addTexture(uint texture, bool depth = false) {
		checkError();

		glBindFramebuffer(GL_FRAMEBUFFER, _buffer);
		glBindTexture(GL_TEXTURE_2D, texture);
		if(!depth) glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + texturesAttached++, texture, 0);
		else glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, texture, 0);
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		checkError();

		return texture;
	}

	void setup() {
		checkError();
		glBindFramebuffer(GL_FRAMEBUFFER, _buffer);

		import core.stdc.stdlib : malloc;
		_drawBuffer = (cast(GLenum *)malloc(texturesAttached * GLenum.sizeof))[0 .. texturesAttached];
		foreach(i; 0 .. texturesAttached) _drawBuffer[i] = GL_COLOR_ATTACHMENT0 + i;

		checkError();

		glDrawBuffers(cast(int)_drawBuffer.length, _drawBuffer.ptr);

		checkError();

		if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			dispose();
			Logger.error("Error setting up FBO for : textures");
			Logger.error(cast(char)(texturesAttached + '0'));
		}

		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		checkError();
	}

	void bind(int viewportWidth, int viewportHeight) {
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _buffer);

		glGetIntegerv(GL_VIEWPORT, old_viewport.ptr);
		glViewport(0, 0, viewportWidth, viewportHeight);

		glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	}

	void unbind() {
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

		glViewport(old_viewport[0], old_viewport[1], old_viewport[2], old_viewport[3]);
	}

	void dispose() {
		glDeleteFramebuffers(1, &_buffer);

		import core.stdc.stdlib : free;
		free(_drawBuffer.ptr);
	}
}