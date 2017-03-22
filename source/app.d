module app;

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import core.memory : GC;

import shared_memory;
import updater;
import renderer;

import isolated.window;
import isolated.utils.timer;
import isolated.graphics.texture;
import isolated.graphics.g3d.model;

import isolated.gui.builder;
import menu.main;
import dominator.main;

int main() {
	mainWindow = new Window("Dominator");
	mainWindow.show();

	currentScreen = new MainMenu();
	lastScreen = null;

	GC.collect();

	mainTimer = Timer().reset;

	UpdateThread updateThread = new UpdateThread();
	RenderThread renderThread = new RenderThread();

	UpdateThread.addMethod(&currentScreen.initUpdate);
	RenderThread.addMethod(&currentScreen.initRender);

	updateThread.start();
	renderThread.start();

	if(currentScreen) {
		currentScreen.destroyUpdate(0);
		currentScreen.destroyRender(0);
	}
	if(lastScreen) {
		lastScreen.destroyUpdate(0);
		lastScreen.destroyRender(0);
	}

	mainWindow.close();
	readln();

	return 0;
}
