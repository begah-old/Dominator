module isolated.screen;

interface Screen {
	void initUpdate(double d);
	void initRender(double d);

	void update(double delta);
	void render(double delta);

	void destroyUpdate(double d);
	void destroyRender(double d);
}

import shared_memory;

import updater;
import renderer;

void switchScreen(Screen screen) {
	UpdateThread.addMethod(&screen.initUpdate);
	RenderThread.addMethod(&screen.initRender);

	lastScreen = currentScreen;

	if(lastScreen !is null) {
		UpdateThread.addMethod(&lastScreen.destroyUpdate);
		RenderThread.addMethod(&lastScreen.destroyRender);
	}

	currentScreen = screen;
}