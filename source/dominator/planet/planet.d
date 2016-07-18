module familysurvival.planet.planet;

import std.conv;
import std.stdio;
import std.string;
import std.algorithm;

import isolated.math;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;
import isolated.graphics.utils.opengl;
import isolated.graphics.camera.camera;
import isolated.graphics.shader;
import isolated.utils.logger;
import isolated.file;
import isolated.window;
import app : window;

class Planet {
  vec3 position;
  vec3 rotation;

  Mesh mesh;
  Shader shader;
  IcoSphere icoSphere;
  int level;

  this(vec3 position) {
    this.position = position;
    this.rotation = vec3(0);

    shader = new Shader("Shaders/default");

    mesh = constructPlanet();

    window.addCallBack(&scroll, true);
	window.addCallBack(&key);

	level = 0;
  }

  void scroll(double x, double y) nothrow {
    level -= cast(int)y;

    if(level > icoSphere.levelCount)
      level = 1;
    if(level < 0)
      level = icoSphere.levelCount;
	
	Logger.info(level);
    Logger.info(to!string(icoSphere.getLevelIndex(level)) ~ " / " ~ to!string(icoSphere.getLevelSize(level)));
  }

  Mesh constructPlanet() {
    icoSphere = new IcoSphere(3);

    Mesh mesh = new Mesh();
    mesh.add(VertexAttribute.Position.add(cast(float[])icoSphere.positions));
	mesh.add(VertexAttribute.Normal.add(cast(float[])icoSphere.normals));
	mesh.add(VertexAttribute.TexCoords.add(cast(float[])icoSphere.texturecoords));
    mesh.generate(shader);

    return mesh;
  }

  void key(int key, int action, int mods) nothrow {
	if(key == GLFW_KEY_I && action) {
		Logger.info("INFO");
	}
  }

  void render(Camera camera) {
    shader.bind();
    shader.uniform("uView", camera.viewMatrix);
    shader.uniform("uProjection", camera.projectionMatrix);
    checkError();
    glBindVertexArray(mesh.vao);

    int start, count;
    if(level == 0) {
      start = 0;
      count = mesh.vertexCount;
    } else {
      start = icoSphere.getLevelIndex(level) * 3;
      count = icoSphere.getLevelSize(level) * 3;
    }

    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
	glDrawArrays(GL_TRIANGLES, start, count);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

    glBindVertexArray(0);

    shader.unbind();
		checkError();
  }
}
