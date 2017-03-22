module renderer;

import shared_memory;

import isolated.utils.timer;
import isolated.graphics.utils.opengl;
import isolated.screen;
import core.sync.mutex;
import core.memory;

private alias RenderCallMethod = void delegate(double);
private __gshared Mutex RenderCallMethodMutex;
private __gshared RenderCallMethod[50] renderMethodList;
private __gshared size_t renderMethodCount;

class RenderThread {
	this() {
		RenderCallMethodMutex = new Mutex();
	}

	void start() {
		double delta = mainTimer.elapsedTime;
		Screen currScreen = currentScreen;

		while(mainWindow.shouldClose() == false) {
			glViewport(0, 0, mainWindow.screenDimension.x, mainWindow.screenDimension.y);
			glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
			glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

			checkError();

			double nextDelta = mainTimer.elapsedTime;
			synchronized(RenderCallMethodMutex) {
				foreach(i; 0 .. renderMethodCount)
					renderMethodList[i](nextDelta - delta);
				renderMethodCount = 0;
			}
			currScreen.render(nextDelta - delta);
			delta = nextDelta;

			checkError();
			mainWindow.refresh();

			GC.collect();
			currScreen = currentScreen;
		}
	}

	static void addMethod(RenderCallMethod method) {
		synchronized(RenderCallMethodMutex) {
			renderMethodList[renderMethodCount++] = method;
		}
	}
}