module menu.main;

import shared_memory : mainWindow;

import isolated.screen;
import isolated.gui;

import isolated.utils.logger;
import isolated.graphics.utils.opengl;
import isolated.math;

import dominator.main;

class MainMenu : Screen {

	FontManager fontManager;
	Gui gui;

	this() {
		mainWindow.addCallBack(&cursorEvent);
		mainWindow.addCallBack(&mouseEvent);
		mainWindow.addCallBack(&characterEvent);
		mainWindow.addCallBack(&keyEvent);
		mainWindow.addCallBack(&resizeEvent);
	}

	void initUpdate(double d) {
	}

	void filePressed(Button button) {
		Logger.info("File pressed");
	}

	void initRender(double d) {
		fontManager = new FontManager("arial");

		gui = new Gui();
		gui.addButton(mainWindow.width / 2 - 60, 3 * mainWindow.height / 4 - 10, 120, 20, "Play").released = &onPlay;
		gui.addButton(mainWindow.width / 2 - 60, 2 * mainWindow.height / 4 - 10, 120, 20, "Option").released = &onOption;
		gui.addButton(mainWindow.width / 2 - 60, 1 * mainWindow.height / 4 - 10, 120, 20, "Exit").released = &onExit;
	}

	void onPlay(Button b, void *userData) {
		switchScreen(new Dominator());
	}

	void onOption(Button b, void *userData) {
		mainWindow.shouldClose(true);
	}

	void onExit(Button b, void *userData) {
		mainWindow.shouldClose(true);
	}

	void cursorEvent(double x, double y) {
		gui.cursorEvent(x, y);
	}

	void mouseEvent(double x, double y, int button, int action) {
		gui.mouseEvent(x, y, button, action);
	}

	void characterEvent(uint character) {
		gui.characterEvent(character);
	}

	void keyEvent(int key, int action, int mods) {
		gui.keyEvent(key, action, mods);
	}

	void resizeEvent(vec2i previous, vec2i current) {
		gui.resizeEvent(previous, current);
	}

	void update(double delta) {

	}

	void render(double delta) {
		gui.render();
	}

	void destroyUpdate(double d) {

	}

	void destroyRender(double d) {
		mainWindow.removeCallBack(&cursorEvent);
		mainWindow.removeCallBack(&mouseEvent);
		mainWindow.removeCallBack(&characterEvent);
		mainWindow.removeCallBack(&keyEvent);
		mainWindow.removeCallBack(&resizeEvent);
	}

	~this() {
		
	}
}