module isolated.graphics.utils.opengl;

public import derelict.opengl3.functions;
public import derelict.opengl3.types;
public import derelict.opengl3.constants;
public import derelict.opengl3.arb;
public import derelict.opengl3.gl3;

import isolated.utils.logger;

@trusted nothrow:

private {
	string gluErrorString(GLenum errorCode) nothrow @nogc @safe
	{
		switch(errorCode) {
			case GL_NO_ERROR:
				return "no error";
			case GL_INVALID_ENUM:
				return "invalid enumerant";
			case GL_INVALID_VALUE:
				return "invalid value";
			case GL_INVALID_OPERATION:
				return "invalid operation";
			case GL_OUT_OF_MEMORY:
				return "out of memory";
			default: return "undefined";
		}
	}
}

void checkError(string filename = __FILE__, size_t line = __LINE__) nothrow @nogc {
	int err = glGetError(); 
	if(err != GL_NO_ERROR) {
		char["Opengl Error : ".length + 20] Error_String;
		Error_String[0 .. "Opengl Error: ".length] = "Opengl Error: ";

		string temp = gluErrorString(err);
		Error_String["Opengl Error: ".length .. "Opengl Error: ".length + temp.length] = temp;
		Error_String["Opengl Error: ".length + temp.length] = '\0';
		Logger.error(temp, filename, line);
	}
}

import gl3n.linalg : Vector;

alias Vector!(ubyte, 4) VColor;

VColor Color(uint r, uint g, uint b, uint a = 255) nothrow @nogc {
	return VColor(cast(ubyte)r, cast(ubyte)g, cast(ubyte)b, cast(ubyte)a);
}