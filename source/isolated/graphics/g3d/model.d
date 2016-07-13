module isolated.graphics.g3d.model;

import std.typecons;
import core.internal.abort;

import isolated.graphics.mesh;
import isolated.graphics.texture;
import isolated.graphics.shader;
import isolated.graphics.utils.opengl;
import isolated.math;
import isolated.file;
import isolated.graphics.vertexattribute;
import isolated.utils.assets;
import std.stdio;
import std.array;
import std.string;
import isolated.utils.logger;

alias ModelManager = ResourceManager!(Model, loadModel, freeModel, "isolated.graphics.g3d.model");
alias ModelType = ModelManager.Handle;

struct Model
{
	Mesh mesh;
	Shader shader;
	TextureType[] textures;

	private {
		this(Mesh mesh, Shader shader, TextureType[] textures...) {
			if(mesh.isGenerated() == false)
				mesh.generate(shader);
			this.mesh = mesh;
			this.shader = shader;
			if(!(textures.length == 1 && textures[0].initialized == false)) {
				this.textures.length = textures.length;
				foreach(i; 0..textures.length) {
					this.textures[i] = textures[i];
				}
			}
		}
	}

	static ModelType create(Mesh mesh, Shader shader, TextureType[] textures...) in { assert(mesh !is null && shader !is null); }
	body {
		Model model = Model(mesh, shader, textures);

		return ModelManager.add(model);
	}

	alias ModelManager.get load;

	void begin() {
		checkError();
		foreach(i, ref texture; this.textures) {
			if(shader.textureSamplers.length <= i)
				break;
			shader.uniform(shader.textureSamplers[i], i);
			texture.bind(i);
		}
		checkError();
		glBindVertexArray(mesh.vao);
		checkError();
	}

	void render(mat4 transformation) {
		checkError();
		shader.uniform("uTransform", transformation);

		glDrawArrays(GL_TRIANGLES, 0, mesh.vertexCount);
		checkError();
	}

	void end() {
		glBindVertexArray(0);

		if(this.textures.length > 0)
			this.textures[0].unbind();
	}
}

private Model referenceModel;

public {
	ref Model loadModel(string modelName, Shader shader) in { assert(shader !is null); }
	body {
		if(modelName.length <= 4) {
			abort(modelName ~ " is not a valid model filename");
		}

		string extensions = modelName[$ - 3 .. $];

		switch(extensions) {
			case "obj":
				referenceModel = loadObjModel(modelName, shader);
				break;
			case "dae":
				referenceModel = loadColladaModel(modelName);
				break;
			default: abort(extensions ~ " not supported model file format");
		}

		return referenceModel;
	}

	Model loadObjModel(string filename, Shader shader) {
		try {
			File modelFile;
			modelFile = internal(filename, "rb");

			vec3[] vertices;
			vec3[] normals;
			vec2[] textcoords;
			vec3i[] facesVertices;
			vec3i[] facesNormals;
			vec3i[] facesTextcoords;

			TextureType texture;

			try {
				foreach(line; modelFile.byLine) {
					if(line.length <= 2) continue;

					auto splits = split(line);

					switch(splits[0]) {
						case "v":
							vertices ~= vec3(to!(float[])(splits[1 .. $]));
							break;
						case "vn":
							normals ~= vec3(to!(float[])(splits[1 .. $]));
							break;
						case "vt":
							textcoords ~= vec2(to!(float[])(splits[1 .. $]));
							break;
						case "f":
							splits = splits[1 .. $];

							int[3] process(char[] splits) {
								char[][] str = split(splits, "/");
								foreach(ref s; str) {
									if(s == "") {
										s = "-1".dup;
									}
								}
								return to!(int[3])(str);
							}

							int[3] integers = process(splits[0]);
							int[3] integers2 = process(splits[1]);
							int[3] integers3 = process(splits[2]);

							if(integers[0] != -1) {
								facesVertices ~= vec3i(integers[0] - 1, integers2[0] - 1, integers3[0] - 1);
							}
							if(integers[1] != -1) {
								facesTextcoords ~= vec3i(integers[1] - 1, integers2[1] - 1, integers3[1] - 1);
							}
							if(integers[2] != -1) {
								facesNormals ~= vec3i(integers[2] - 1, integers2[2] - 1, integers3[2] - 1);
							}
							break;
						case "mtllib":
							int ind = lastIndexOf(filename, '/');
							auto MaterialFile = internal(ind == -1 ? splits[1] : filename[0 .. ind + 1] ~ splits[1], "rb");

							foreach(line2; MaterialFile.byLine) {
								if(line2.length == 0)
									continue;

								auto splits2 = split(line2);

								if(splits2[0] == "map_Kd") {
									if(splits2[1] == "")
										texture = Texture.load((ind == -1 ? splits2[2] : filename[0 .. ind + 1] ~ splits2[2]).idup);
									else {
										texture = Texture.load((ind == -1 ? splits2[1] : filename[0 .. ind + 1] ~ splits2[1]).idup);
									}
									break;
								}
							}
							MaterialFile.close();
							break;
						default:break;
					}
				}
			} catch(Exception ex) {
				return Model.init;
			}

			Mesh mesh = new Mesh();

			if(facesVertices.length > 0) {
				float[] verts = new float[9 * facesVertices.length];
				foreach(i, vector; facesVertices) {
					vec3 v = vertices[vector.x];
					verts[i * 9] = v.x;
					verts[i * 9 + 1] = v.y;
					verts[i * 9 + 2] = v.z;

					v = vertices[vector.y];
					verts[i * 9 + 3] = v.x;
					verts[i * 9 + 4] = v.y;
					verts[i * 9 + 5] = v.z;

					v = vertices[vector.z];
					verts[i * 9 + 6] = v.x;
					verts[i * 9 + 7] = v.y;
					verts[i * 9 + 8] = v.z;
				}

				mesh.add(VertexAttribute.Position().add(verts));

				if(facesNormals.length > 0) {
					if(facesNormals.length != facesVertices.length) {
						abort(filename ~ " doesn't have the same number of normals than vertices");
					}

					float[] norms = new float[9 * facesNormals.length];
					foreach(i, vector; facesNormals) {
						vec3 v = normals[vector.x];
						norms[i * 9] = v.x;
						norms[i * 9 + 1] = v.y;
						norms[i * 9 + 2] = v.z;

						v = normals[vector.y];
						norms[i * 9 + 3] = v.x;
						norms[i * 9 + 4] = v.y;
						norms[i * 9 + 5] = v.z;

						v = normals[vector.z];
						norms[i * 9 + 6] = v.x;
						norms[i * 9 + 7] = v.y;
						norms[i * 9 + 8] = v.z;
					}

					mesh.add(VertexAttribute.Normal().add(norms));
				}
				if(facesTextcoords.length > 0) {
					if(facesTextcoords.length != facesVertices.length) {
						abort(filename ~ " doesn't have the same number of texture coordinates than vertices");
					}

					float[] textcoord = new float[6 * facesTextcoords.length];
					foreach(i, vector; facesTextcoords) {
						vec2 v = textcoords[vector.x];
						textcoord[i * 6] = v.x;
						textcoord[i * 6 + 1] = v.y;

						v = textcoords[vector.y];
						textcoord[i * 6 + 2] = v.x;
						textcoord[i * 6 + 3] = v.y;

						v = textcoords[vector.z];
						textcoord[i * 6 + 4] = v.x;
						textcoord[i * 6 + 5] = v.y;
					}

					mesh.add(VertexAttribute.TexCoords().add(textcoord));
				}
			}

			return Model(mesh, shader, texture);
		} catch(Exception ex) {return Model.init;}
	}

	Model loadColladaModel(string filename) {
		return Model.init;
	}
}

void freeModel(Model model) {
	Logger.info("Hello : " ~ model.textures[0].name);
}
