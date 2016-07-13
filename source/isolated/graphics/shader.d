module isolated.graphics.shader;

import std.stdio;
import std.string;
import core.internal.abort;
import std.regex;
import std.conv;

import isolated.file;
import isolated.math;
import isolated.graphics.utils.opengl;
import isolated.graphics.vertexattribute;
import isolated.utils.logger;

class Shader
{
	GLuint id;
	GLint[string] uniforms;

	struct VertexAttribute_Info {
		VertexAttribute.Usage usage;
		size_t location;

		alias usage this;
	}

	VertexAttribute_Info[] vertexAttributes;
	string[] textureSamplers;

	this(string filename) {
		this(filename ~ "-vertex.glsl", filename ~ "-fragment.glsl");
	}

	this(string vertexFile, string fragmentFile) {
		this(internal(vertexFile, "rb"), internal(fragmentFile, "rb"));
	}

	this(File vertexShader, File fragmentShader, bool closeFiles = true) {
		char[] vertex = new char[cast(uint) vertexShader.size + 1];
		vertexShader.rawRead(vertex);
		vertex[cast(uint) vertexShader.size] = '\0';

		char[] fragment = new char[cast(uint) fragmentShader.size + 1];
		fragmentShader.rawRead(fragment);
		fragment[cast(uint) fragmentShader.size] = '\0';

		this(vertex, fragment);

		if(closeFiles) {
			vertexShader.close();
			fragmentShader.close();
		}
	}

	this(const(char)[] vertexSource, const(char)[]
		fragmentSource, bool analyze = true) {
		GLuint vertexShader, fragmentShader;
		GLint Linked;

		vertexShader = compilePiece(cast(char *)vertexSource, GL_VERTEX_SHADER);

		if(vertexShader == 0) {
			return;
		}

		fragmentShader = compilePiece(cast(char *)fragmentSource, GL_FRAGMENT_SHADER);

		if(fragmentShader == 0) {
			return;
		}

		id = glCreateProgram();

		if(id == 0)
			abort("Could not create shader program");

		glAttachShader(id, vertexShader);
		glAttachShader(id, fragmentShader);

		checkError();

		glLinkProgram(id);

		glGetProgramiv(id, GL_LINK_STATUS, &Linked);

		if(!Linked)
		{
			GLint infoLen = 0;
			glGetProgramiv(id, GL_INFO_LOG_LENGTH, &infoLen);

			if(infoLen > 1)
			{
				char[] infoLog = new char[infoLen + 50];

				glGetProgramInfoLog(id, infoLen, null, cast(char *)infoLog);
				abort("error linking program : " ~ to!string(infoLog));
			}

			glDeleteProgram(id);
			id = GLuint.init;

			return;
		}

		checkError();

		if(analyze) { // Analyze shader to determine attributes
			analyzeAttributes(vertexSource);
			analyzeTextureSamplers(fragmentSource);
		}
	}

	void bind() {
		glUseProgram(id);
	}

	void unbind() {
		glUseProgram(0);
	}

	void uniform(string name, int value) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform1i(uniforms[name], value);
	}

	void uniform(string name, mat4 matrix) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniformMatrix4fv(uniforms[name], 1, cast(ubyte)true, cast(const(float) *)matrix.value_ptr);
	}

	void uniform(string name, vec2 vector) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform2f(uniforms[name], vector.x, vector.y);
	}

	void uniform(string name, vec3 vector) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform3f(uniforms[name], vector.x, vector.y, vector.z);
	}

	void uniform(string name, vec4 vector) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform4f(uniforms[name], vector.x, vector.y, vector.z, vector.w);
	}

	void uniform(string name, vec2i vector) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform2f(uniforms[name], vector.x, vector.y);
	}

	void uniform(string name, vec3i vector) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform3i(uniforms[name], vector.x, vector.y, vector.z);
	}

	void uniform(string name, vec4i vector) {
		if(!(name in uniforms)) {
			uniforms[name] = glGetUniformLocation(id, name.toStringz);
		}
		glUniform4i(uniforms[name], vector.x, vector.y, vector.z, vector.w);
	}

	~this() {
		if(id != GLuint.init) {
			glDeleteProgram(id);
		}
	}

	private {
		GLuint compilePiece(char *src, GLenum type)
		{
			GLuint shader;
			GLint Compiled;

			shader = glCreateShader(type);

			if(shader == 0)
				abort("Could not create shader program");

			glShaderSource(shader, 1, cast(const char **) &src, null);

			glCompileShader(shader);

			glGetShaderiv(shader, GL_COMPILE_STATUS, &Compiled);

			if(!Compiled)
			{
				GLint infoLen = 0;

				glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);

				if(infoLen > 1)
				{
					char[] infoLog = new char[infoLen];

					glGetShaderInfoLog(shader, infoLen, null, cast(char *)infoLog);
					abort(infoLog.idup);
				}

				glDeleteShader(shader);
				return 0;
			}
			return shader;
		}

		void analyzeAttributes(const(char)[] vertexSource) {
			int index = vertexSource.indexOf("in", CaseSensitive.yes);
			const(char)[] source = vertexSource;

			string attributeName = "in ";

			if(index == -1) { // Search for attributes instead
				attributeName = "attribute ";
				index = vertexSource.indexOf(attributeName, CaseSensitive.yes);
			}

			auto locationRegex = regex(r"^layout \(location = ([0-9]+)\)");

			if(index != -1) {
				do {
					const(char)[] attribute = source[index + attributeName.length + 1 .. source.indexOf(";")].split(' ')[1];

					size_t location = vertexAttributes.length;

					int ind = lastIndexOf(source[0 .. index], '\n');
					ind = ind == -1 ? 0 : ind + 1;
					const(char)[] locationSource = source[ind .. index];

					auto finding = matchFirst(locationSource, locationRegex);

					if(finding.captures.length == 2)
						location = to!size_t(finding.captures[1]);

					switch(attribute) {
						case "aposition":
							vertexAttributes ~= VertexAttribute_Info(VertexAttribute.Usage.Position, location);
							break;
						case "acolor":
							vertexAttributes ~= VertexAttribute_Info(VertexAttribute.Usage.ColorPacked, location);
							break;
						case "atextcoord":
							vertexAttributes ~= VertexAttribute_Info(VertexAttribute.Usage.TextureCoordinates, location);
							break;
						case "anormal":
							vertexAttributes ~= VertexAttribute_Info(VertexAttribute.Usage.Normal, location);
							break;
						default: break;
					}

					source = source[index + source[index .. $].indexOf('\n') + 1 .. $];

					index = source.indexOf(attributeName, CaseSensitive.yes);
				} while(index != -1);
			}
		}

		void analyzeTextureSamplers(const(char)[] fragmentSource) {
			auto samplerRegex = regex(r"uniform sampler2D (.+);");
			auto arrayRegex = regex(r"[(.+)];");

			const(char)[] source = fragmentSource;

			auto match = source.matchFirst(samplerRegex);

			while(match.length != 0) {

				auto arrayMatch = match[1].matchFirst(arrayRegex);

				if(arrayMatch.length == 0) { // All fine, not an array
					textureSamplers ~= match[1].dup;
				} else { // Array, fuck

				}

				source = source[match.pre.length + match.hit.length .. $];

				match = source.matchFirst(samplerRegex);
			}
		}
	}
}
