module isolated.graphics.utils.framebuffer;

import isolated.graphics.utils.opengl;
import isolated.utils.logger;

struct FrameBuffer {
	@nogc nothrow :

	private GLuint _buffer;
	private int texturesAttached;	
	private GLenum[] _drawBuffer;
	private GLint[4] old_viewport;

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

	void addTexture(GLuint texture) {
		checkError();

		glBindFramebuffer(GL_FRAMEBUFFER, _buffer);
		glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + texturesAttached++, texture, 0);
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		checkError();
	}

	void setup() {
		checkError();
		glBindFramebuffer(GL_FRAMEBUFFER, _buffer);

		import core.stdc.stdlib : malloc;
		_drawBuffer = (cast(GLenum *)malloc(texturesAttached * GLenum.sizeof))[0 .. texturesAttached];
		foreach(i; 0 .. texturesAttached) _drawBuffer[i] = GL_COLOR_ATTACHMENT0 + i;

		checkError();

		glDrawBuffers(1, _drawBuffer.ptr);

		checkError();

		if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
			dispose();
			Logger.error("Error setting up FBO for : textures");
			Logger.error(cast(char)(texturesAttached + '0'));
		}

		checkError();
	}

	void bind(int viewportWidth, int viewportHeight) {
		glBindFramebuffer(GL_FRAMEBUFFER, _buffer);

		glGetIntegerv(GL_VIEWPORT, old_viewport.ptr);
		glViewport(0, 0, viewportWidth, viewportHeight);
	}

	void unbind() {
		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		glViewport(old_viewport[0], old_viewport[1], old_viewport[2], old_viewport[3]);
	}

	void dispose() {
		glDeleteFramebuffers(1, &_buffer);

		import core.stdc.stdlib : free;
		free(_drawBuffer.ptr);
	}
}