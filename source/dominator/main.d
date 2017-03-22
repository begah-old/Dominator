module dominator.main;

import core.sync.mutex;

import isolated.math;
import isolated.graphics.camera.perspective;
import isolated.graphics.camera.controller;
import isolated.graphics.utils.opengl;
import isolated.graphics.g3d.model;
import isolated.graphics.g3d.modelinstance;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;
import isolated.graphics.utils.framebuffer;
import isolated.graphics.texture;
import isolated.graphics.shader;
import isolated.utils.logger;
import isolated.gui;

import dominator.planet;

import shared_memory;
import isolated.window;
import isolated.screen;

class Dominator : Screen {
	Planet[] planets;
	Tile*[] selectedTile;
  
	PerspectiveCamera updateCamera, renderCamera;
	CameraController controller;
	Mutex cameraMutex;

	Gui gui;
	Panel tilePanel;

	DominatorRenderer dominatorRenderer;

	private class DominatorRenderer {
		FrameBuffer guiBuffer, sceneBuffer;
		Texture guiColor, guiDepth;
		Texture sceneColor, sceneDepth;

		Shader postProcessing;
		Mesh postProcessingMesh;

		this() {
			sceneBuffer = FrameBuffer(true);
			sceneColor = sceneBuffer.addTexture(Texture.generateColorTexture(mainWindow.width, mainWindow.height));
			sceneDepth = sceneBuffer.addTexture(Texture.generateDepthTexture(mainWindow.width, mainWindow.height), true);
			sceneBuffer.setup();

			guiBuffer = FrameBuffer(true);
			guiColor = guiBuffer.addTexture(Texture.generateColorTexture(mainWindow.width, mainWindow.height));
			guiDepth = guiBuffer.addTexture(Texture.generateDepthTexture(mainWindow.width, mainWindow.height), true);
			guiBuffer.setup();

			postProcessing = new Shader("post_processor");
			postProcessingMesh = Mesh.Square(-1.0f, -1.0f, 2.0f, 2.0f, 0, VertexAttribute.Usage.Position | VertexAttribute.Usage.TextureCoordinates);
			postProcessingMesh.generate(postProcessing);
		}

		void renderUpdate() {
			synchronized(cameraMutex) {
				renderCamera.set(updateCamera);
			}
			renderCamera.calculate();

			if(selectedTile.length != 0) {
				(cast(EnumButton)tilePanel.elements[4]).setEnum(selectedTile[0].biome.biomeType);
			}
		}

		void renderPlanets() {
			glEnable(GL_DEPTH_TEST);

			foreach(planet; planets)
				planet.render(renderCamera);

			glDisable(GL_DEPTH_TEST);
		}

		void renderEntities() {

		}

		void masterRender() {
			renderUpdate();
			checkError();

			sceneBuffer.bind(mainWindow.width, mainWindow.height);

			renderPlanets();
			renderEntities();
			
			sceneBuffer.unbind();

			guiBuffer.bind(mainWindow.width, mainWindow.height);

			glEnable(GL_DEPTH_TEST);
			glDepthFunc(GL_LEQUAL);
			gui.render();
			glDisable(GL_DEPTH_TEST);

			guiBuffer.unbind();

			checkError();

			postProcessing.bind();
			postProcessing.uniform("guiSampler", 0);
			postProcessing.uniform("guiDepthSampler", 1);
			postProcessing.uniform("sceneSampler", 2);
			guiColor.bind();
			guiDepth.bind(1);
			sceneColor.bind(2);

			glBindVertexArray(postProcessingMesh.vao);
			glDrawArrays(GL_TRIANGLES, 0, cast(GLint)postProcessingMesh.vertexCount);
			glBindVertexArray(0);
			sceneColor.unbind();
			guiColor.unbind();
			postProcessing.unbind();
		}
	}

	this() {
		cameraMutex = new Mutex();

		updateCamera = new PerspectiveCamera(mainWindow.screenDimension);
		updateCamera.translate(vec3(0, 0, 0));
		controller = new CameraController(updateCamera, mainWindow);

		renderCamera = new PerspectiveCamera(mainWindow.screenDimension);
		renderCamera.set(updateCamera);

		planets ~= new Planet(this, vec3(0), 5);
	}

	void initUpdate(double d) {
	}

	void initRender(double d) {
		dominatorRenderer = new DominatorRenderer();

		gui = new Gui();
		tilePanel = new Panel(500, 480, 140, 200);
		tilePanel.anchor(GuiElement.Anchor.Left | GuiElement.Anchor.Up);
		Textbox textbox = tilePanel.addTextbox("Tile id : ", "0", 140, 15);
		textbox.released = &guiCallback; textbox.userData = cast(void*)1;
		tilePanel.addLabel("V1 : ", 140, 15);
		tilePanel.addLabel("V2 : ", 140, 15);
		tilePanel.addLabel("V3 : ", 140, 15);
		tilePanel.addEnumButton("Biome : ", 140, 15).addEnum("Plain", Biome.Types.PLAIN).addEnum("Forest", Biome.Types.FOREST).addEnum("Rain forest", Biome.Types.RAINFOREST).addEnum("Sand desert", Biome.Types.SAND_DESERT).addEnum("Snow desert", Biome.Types.SNOW_DESERT).callback = &changedBiome;
		gui.add(tilePanel);

		mainWindow.addCallBack(&cursorEvent);
		mainWindow.addCallBack(&mouseEvent);
		mainWindow.addCallBack(&characterEvent);
		mainWindow.addCallBack(&keyEvent);
		mainWindow.addCallBack(&resizeEvent);
	}

	void changedBiome(EnumButton eb, size_t enumValue) {
		foreach(t; selectedTile) {
			t.setBiome(Biome(cast(Biome.Types)enumValue, 3, cast(Biome.Types)enumValue));
		}
	}

	void refreshTileInformation() {
		try {
			size_t tileID = (cast(Textbox)tilePanel.elements[0]).value.to!int;
			if(tileID >= planets[0].tileCount) {
				tileID = planets[0].tileCount - 1;
				(cast(Textbox)tilePanel.elements[0]).value(tileID.to!string);
			}
			selectedTile[0] = planets[0].tiles + tileID;
			Label l = cast(Label)tilePanel.elements[1];
			l.changeText("V1 : (" ~ selectedTile[0].vertices[0].x.to!string ~ "," ~ selectedTile[0].vertices[0].y.to!string ~ "," ~ selectedTile[0].vertices[0].z.to!string ~ ")");
			l = cast(Label)tilePanel.elements[2];
			l.changeText("V2 : (" ~ selectedTile[0].vertices[1].x.to!string ~ "," ~ selectedTile[0].vertices[1].y.to!string ~ "," ~ selectedTile[0].vertices[1].z.to!string ~ ")");
			l = cast(Label)tilePanel.elements[3];
			l.changeText("V3 : (" ~ selectedTile[0].vertices[2].x.to!string ~ "," ~ selectedTile[0].vertices[2].y.to!string ~ "," ~ selectedTile[0].vertices[2].z.to!string ~ ")");
		} catch(Exception ex) {
			Logger.info(ex);
		}
	}

	void guiCallback(Button b, void *data) {
		int id = cast(int)data;

		switch(id) {
		case 1:
			refreshTileInformation();
			break;

		default:break;
		}
	}

	void characterEvent(uint character) {
		gui.characterEvent(character);
	}

	bool controlPressed;
	void keyEvent(int key, int action, int mods) {
		if(key == GLFW_KEY_LCTRL)
			controlPressed = action ? true : false;
		if(action != GLFW_PRESS) return;

		if(key == GLFW_KEY_I) {
			Logger.info("INFO : ");

			Logger.info("Tile id : " ~ selectedTile[0].id.to!string);
			Logger.info("Level of tile : " ~ selectedTile[0].planet.icoSphere.Tile_Level(selectedTile[0].id).to!string);
			Logger.info("Level index : " ~ selectedTile[0].planet.icoSphere.getLevelIndex(selectedTile[0].planet.icoSphere.Tile_Level(selectedTile[0].id)).to!string);
			Logger.info("Level size : " ~ selectedTile[0].planet.icoSphere.getLevelSize(selectedTile[0].planet.icoSphere.Tile_Level(selectedTile[0].id)).to!string);
		} else if(key == GLFW_KEY_0) {
			selectedTile[0].biome = selectedTile[0]._newBiome = Biome(Biome.Types.SAND_DESERT, Biome.Max_Strenght, Biome.Types.SAND_DESERT);
			selectedTile[0].setColor(selectedTile[0].biome.calculateColor());
		} else {
			gui.keyEvent(key, action, mods);
		}
	}

	void cursorEvent(double x, double y) {
		gui.cursorEvent(x, y);
	}

	void mouseEvent(double x, double y, int button, int action) {
		if(button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
			if(gui.mouseEvent(x, y, button, action)) return;
			
			Ray ray = updateCamera.getRay(x, y);
			size_t length = 1000000;
			Tile* newTile;

			foreach(planet; planets) {
				foreach(i; 0 .. planet.tileCount) {
					if(ray.intersects(planet.tiles[i].vertices[0], planet.tiles[i].vertices[1], planet.tiles[i].vertices[2])) {
						vec3 middle = (planet.tiles[i].vertices[0] + planet.tiles[i].vertices[1] + planet.tiles[i].vertices[2]) / 3.0f;
						middle -= updateCamera.translation;
						if(middle.length < length) {
							newTile = planet.tiles + i;
							length = cast(size_t)middle.length;
						}
					}
				}
			}

			if(controlPressed && newTile !is null)
				selectedTile ~= newTile;
			else if(newTile !is null) {
				selectedTile.length = 1;
				selectedTile[0] = newTile;
			}

			if(selectedTile.length != 0) {
				(cast(Textbox)tilePanel.elements[0]).value(selectedTile[0].id.to!string);
				refreshTileInformation();
			}
		}
	}

	void update(double delta) {
		synchronized(cameraMutex) {
			updateCamera.update(delta);
		}

		foreach(planet; planets)
			planet.update(updateCamera, delta);
	}

	void render(double delta) {
		dominatorRenderer.masterRender();
	}

	void resizeEvent(vec2i previous, vec2i current) {
		gui.resizeEvent(previous, current);
	}

	void destroyUpdate(double d) {

	}

	void destroyRender(double d) {

	}

	~this() {
	}
}