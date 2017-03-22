module updater;

import core.thread;
import core.sync.mutex;
import isolated.screen;

import shared_memory;

private alias UpdateCallMethod = void delegate(double);
private __gshared Mutex UpdateCallMethodMutex;
private __gshared UpdateCallMethod[50] updateMethodList;
private __gshared size_t updateMethodCount;

class UpdateThread : Thread {

	this() {
		super(&update);

		UpdateCallMethodMutex = new Mutex();
	}

	void update() {
		double delta = mainTimer.elapsedTime;
		Screen currScreen = currentScreen;

		while(mainWindow.shouldClose() == false) {
			double nextDelta = mainTimer.elapsedTime;
			
			synchronized(UpdateCallMethodMutex) {
				foreach(i; 0 .. updateMethodCount)
					updateMethodList[i](nextDelta - delta);
				updateMethodCount = 0;
			}
			currentScreen.update(nextDelta - delta);

			currScreen = currentScreen;
			delta = mainTimer.elapsedTime;
		}
	}

	static void addMethod(UpdateCallMethod method) {
		synchronized(UpdateCallMethodMutex) {
			updateMethodList[updateMethodCount++] = method;
		}
	}
}