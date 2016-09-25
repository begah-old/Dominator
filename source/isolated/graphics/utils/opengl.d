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
	/*int err = glGetError(); 
	if(err != GL_NO_ERROR) {
		char["Opengl Error : ".length + 20] Error_String;
		Error_String[0 .. "Opengl Error: ".length] = "Opengl Error: ";

		string temp = gluErrorString(err);
		Error_String["Opengl Error: ".length .. "Opengl Error: ".length + temp.length] = temp;
		Error_String["Opengl Error: ".length + temp.length] = '\0';
		Logger.error(temp, filename, line);
	}*/
}

struct Color {
	ubyte[4] rgba;

	@safe nothrow @nogc :

	private @property ref inout(ubyte) get_(char coord)() inout {
        return rgba[coord_to_index!coord];
    }

	template coord_to_index(char c) {
		static if(c == 'r') enum coord_to_index = 0;
		static if(c == 'g') enum coord_to_index = 1;
		static if(c == 'b') enum coord_to_index = 2;
		static if(c == 'a') enum coord_to_index = 3;
	}

	alias get_!'r' r;
	alias get_!'g' g;
	alias get_!'b' b;
	alias get_!'a' a;

	this(ubyte color) {
		rgba[0 .. 4] = color;
	}
	this(ubyte r, ubyte g, ubyte b, ubyte a = 255) {
		rgba[0] = r; rgba[1] = g; rgba[2] = b; rgba[3] = a;
	}

	Color opBinary(string op, T)(T rhs) {
		foreach(ref ub; rgba) {
			mixin("ub = cast(ubyte)(ub " ~ op ~ " rhs);");
		}

		return this;
	}
}
