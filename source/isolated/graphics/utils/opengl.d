module isolated.graphics.utils.opengl;

public import derelict.opengl3.functions;
public import derelict.opengl3.types;
public import derelict.opengl3.constants;
public import derelict.opengl3.arb;
public import derelict.opengl3.gl3;

import isolated.utils.logger;

shared static this() {
	Errors = [
		GL_NO_ERROR: "no error",
		GL_INVALID_ENUM: "invalid enumerant",
		GL_INVALID_VALUE: "invalid value",
		GL_INVALID_OPERATION: "invalid operation",
		GL_OUT_OF_MEMORY: "out of memory"
	];
}

@trusted nothrow:

private {
	immutable string[int] Errors;
	string gluErrorString(GLenum errorCode)
	{
		return Errors[errorCode];
	}
}

void checkError(string filename = __FILE__, size_t line = __LINE__) {
	int err = glGetError(); 
	if(err != GL_NO_ERROR) {
		Logger.error("Opengl Error: " ~ gluErrorString(err), filename, line);
	}
}