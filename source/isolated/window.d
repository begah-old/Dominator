module isolated.window;

public import derelict.glfw3.glfw3;
public import derelict.glfw3.types;

import derelict.glfw3.dynload;

import isolated.graphics.utils.opengl;
import isolated.math;
import isolated.utils.logger;
import isolated.utils.timer;

import std.string;
import core.thread;

shared static this() {
	DerelictGLFW3.load();
	DerelictGL3.load();

	/* Initialize the library */
	if (!glfwInit())
		abort("Could not initialize glfw3");
}

Window[long] Window_List;

extern(C) void CKeyCallBack(GLFWwindow *window, int key, int scancode, int action, int mods) nothrow
{
	long hash = cast(long)window;
	if(hash in Window_List) {
		Window_List[hash].KeyCallBack(key, action, mods);
	}
}

extern(C) void CCursorCallBack(GLFWwindow *window, double x, double y) nothrow
{
	long hash = cast(long)window;
	if(hash in Window_List) {
		Window_List[hash].CursorCallBack(x, y);
	}
}

extern(C) void CScrollCallBack(GLFWwindow *window, double x, double y) nothrow
{
	long hash = cast(long)window;
	if(hash in Window_List) {
		Window_List[hash].ScrollCallback(x, y);
	}
}

extern(C) void CCursorButtonCallBack(GLFWwindow* window, int button, int action, int mods) nothrow
{
	long hash = cast(long)window;
	if(hash in Window_List) {
		Window_List[hash].MouseCallBack(button, action, mods);
	}
}

extern(C) void CCharacterCallback(GLFWwindow* window, uint character) nothrow
{
	if(character >= 127) return;
	long hash = cast(long)window;
	if(hash in Window_List) {
		Window_List[hash].CharacterCallBack(character);
	}
}

private alias f_keyCallBack = void function(int key, int action, int mods);
private alias f_characterCallBack = void function(uint character);
private alias f_cursorCallBack = void function(double x, double y);
private alias f_mouseCallBack = void function(double x, double y, int button, int action);

private alias d_keyCallBack = void delegate(int key, int action, int mods);
private alias d_characterCallBack = void delegate(uint character);
private alias d_cursorCallBack = void delegate(double x, double y);
private alias d_mouseCallBack = void delegate(double x, double y, int button, int action);

private alias d_resizeCallBack = void delegate(vec2i previous, vec2i current);

private {
	import isolated.screen;

	class EmptyScreen : Screen {
		void initUpdate(double d) {}
		void initRender(double d) {}

		void update(double delta) {}
		void render(double delta) {}

		void destroyUpdate(double d) {}
		void destroyRender(double d) {}
	}
}

class Window {
	GLFWwindow *window;
	bool visible, shouldCloseWindow;

	string title;
	int width, height;
	double currentFps = 60, averageFps = 60;

	f_keyCallBack[] f_keyCallBacks; d_keyCallBack[] d_keyCallBacks;
	f_characterCallBack[] f_characterCallBacks; d_characterCallBack[] d_characterCallBacks;
	f_cursorCallBack[] f_cursorCallBacks, f_scrollCallBacks; d_cursorCallBack[] d_cursorCallBacks, d_scrollCallBacks;
	f_mouseCallBack[] f_mouseCallBacks; d_mouseCallBack[] d_mouseCallBacks;
	d_resizeCallBack[] d_resizeCallBacks;

	vec2d cursorPosition;
	bool setCursorPosition = false;

	private Timer timer;

	this() {
		this("Untitled");
	}

	this(string title) {
		this(title, 640, 480);
	}

	this(string title, int width, int height) {
		this.title = title;
		visible = false;
		shouldCloseWindow = false;

		this.width = width;
		this.height = height;
	}

	void show() {
		if(visible == true)
			return;

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

		window = glfwCreateWindow(width, height, toStringz(title), null, null);

		if (!window)
		{
			Logger.error("Could not create window");
			abort("requested width : " ~ to!string(width) ~ " requested height : " ~ to!string(height));
			visible = false;
		}

		glfwSetKeyCallback(window, &CKeyCallBack);
		glfwSetCharCallback(window, &CCharacterCallback);
		glfwSetCursorPosCallback(window, &CCursorCallBack);
		glfwSetScrollCallback(window, &CScrollCallBack);
		glfwSetMouseButtonCallback(window, &CCursorButtonCallBack);

		glfwMakeContextCurrent(window);

		if(setCursorPosition) {
			glfwSetCursorPos(window, cursorPosition.x, cursorPosition.y);
			setCursorPosition = false;
		}

		try {
			DerelictGL3.reload(GLVersion.GL33);
		} catch(Exception ex) {
			abort(ex.msg);
		}

		visible = true;

		Window_List[cast(long)window] = this;

		timer = Timer();
	}

	void addCallBack(f_keyCallBack cb) {
		this.f_keyCallBacks ~= cb;
	}
	void addCallBack(f_characterCallBack cb) {
		this.f_characterCallBacks ~= cb;
	}

	/* isScroll : True for scroll callback, False for mouse position callback */
	void addCallBack(f_cursorCallBack cb, bool isScroll = false) {
		if(!isScroll) this.f_cursorCallBacks ~= cb;
		else this.f_scrollCallBacks ~= cb;
	}
	void removeCallBack(f_cursorCallBack cb, bool isScroll = false) {
		if(!isScroll) {
			foreach(i; 0 .. f_cursorCallBacks.length) {
				if(f_cursorCallBacks[i] == cb) {
					f_cursorCallBacks[i] = f_cursorCallBacks[$ - 1];
					f_cursorCallBacks.length--;
					return;
				}
			}
		} else {
			foreach(i; 0 .. f_scrollCallBacks.length) {
				if(f_scrollCallBacks[i] == cb) {
					f_scrollCallBacks[i] = f_scrollCallBacks[$ - 1];
					f_scrollCallBacks.length--;
					return;
				}
			}
		}
	}

	void addCallBack(f_mouseCallBack cb) {
		this.f_mouseCallBacks ~= cb;
	}
	void removeCallBack(f_mouseCallBack cb) {
		foreach(i; 0 .. f_mouseCallBacks.length) {
			if(f_mouseCallBacks[i] == cb) {
				f_mouseCallBacks[i] = f_mouseCallBacks[$ - 1];
				f_mouseCallBacks.length--;
				return;
			}
		}
	}

	void addCallBack(d_keyCallBack cb) {
		this.d_keyCallBacks ~= cb;
	}
	void removeCallBack(d_keyCallBack cb) {
		foreach(i; 0 .. d_keyCallBacks.length) {
			if(d_keyCallBacks[i] == cb) {
				d_keyCallBacks[i] = d_keyCallBacks[$ - 1];
				d_keyCallBacks.length--;
				return;
			}
		}
	}

	void addCallBack(d_characterCallBack cb) {
		this.d_characterCallBacks ~= cb;
	}
	void removeCallBack(d_characterCallBack cb) {
		foreach(i; 0 .. d_characterCallBacks.length) {
			if(d_characterCallBacks[i] == cb) {
				d_characterCallBacks[i] = d_characterCallBacks[$ - 1];
				d_characterCallBacks.length--;
				return;
			}
		}
	}

	/* isScroll : True for scroll callback, False for mouse position callback */
	void addCallBack(d_cursorCallBack cb, bool isScroll = false) {
		if(!isScroll) this.d_cursorCallBacks ~= cb;
		else this.d_scrollCallBacks ~= cb;
	}
	void removeCallBack(d_cursorCallBack cb, bool isScroll = false) {
		if(!isScroll) {
			foreach(i; 0 .. d_cursorCallBacks.length) {
				if(d_cursorCallBacks[i] == cb) {
					d_cursorCallBacks[i] = d_cursorCallBacks[$ - 1];
					d_cursorCallBacks.length--;
					return;
				}
			}
		} else {
			foreach(i; 0 .. d_scrollCallBacks.length) {
				if(d_scrollCallBacks[i] == cb) {
					d_scrollCallBacks[i] = d_scrollCallBacks[$ - 1];
					d_scrollCallBacks.length--;
					return;
				}
			}
		}
	}

	void addCallBack(d_mouseCallBack cb) {
		this.d_mouseCallBacks ~= cb;
	}
	void removeCallBack(d_mouseCallBack cb) {
		foreach(i; 0 .. d_mouseCallBacks.length) {
			if(d_mouseCallBacks[i] == cb) {
				d_mouseCallBacks[i] = d_mouseCallBacks[$ - 1];
				d_mouseCallBacks.length--;
				return;
			}
		}
	}

	void addCallBack(d_resizeCallBack cb) {
		this.d_resizeCallBacks ~= cb;
	}
	void removeCallBack(d_resizeCallBack cb) {
		foreach(i; 0 .. d_resizeCallBacks.length) {
			if(d_resizeCallBacks[i] == cb) {
				d_resizeCallBacks[i] = d_resizeCallBacks[$ - 1];
				d_resizeCallBacks.length--;
				return;
			}
		}
	}

	private void KeyCallBack(int key, int action, int mods) nothrow {
		try {
			foreach(cb; this.f_keyCallBacks) {
				cb(key, action, mods);
			}foreach(cb; this.d_keyCallBacks) {
				cb(key, action, mods);
			}

			if(key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
				this.shouldClose(true);
			}
		} catch(Exception ex) {}
	}

	private void CharacterCallBack(uint character) nothrow {
		try {
			foreach(cb; this.f_characterCallBacks) {
				cb(character);
			}foreach(cb; this.d_characterCallBacks) {
				cb(character);

			}
		} catch(Exception ex) {}
	}

	private void CursorCallBack(double x, double y) nothrow {
		try {
			cursorPosition.x = x; cursorPosition.y = height - y;
			foreach(cb; this.f_cursorCallBacks) {
				cb(x, height - y);
			}foreach(cb; this.d_cursorCallBacks) {
				cb(x, height - y);
			}
		} catch(Exception ex) {}
	}

	private void ScrollCallback(double x, double y) nothrow {
		try {
			foreach(cb; this.f_scrollCallBacks) {
				cb(x, y);
			}foreach(cb; this.d_scrollCallBacks) {
				cb(x, y);
			}
		} catch(Exception ex) {}
	}

	private void MouseCallBack(int button, int action, int mods) nothrow {
		try {
			foreach(cb; this.f_mouseCallBacks) {
				cb(cursorPosition.x, cursorPosition.y, button, action);
			}foreach(cb; this.d_mouseCallBacks) {
				cb(cursorPosition.x, cursorPosition.y, button, action);
			}
		} catch(Exception ex) {}
	}

	private int frameCount = 0;
	private double frameFpsCount = 0;

	void refresh() {
		if(visible == false)
			return;

		double time = timer.elapsedTime();
		timer.reset();

		if(time > 0.0) {
			currentFps = 1000.0 / time;
			frameCount++;
			frameFpsCount += currentFps;
		}

		if(frameCount == 60) {
			averageFps = cast(int) (frameFpsCount / 60);
			frameCount = 0; frameFpsCount = 0;
		}

		glfwSwapBuffers(window);
		glfwPollEvents();

		int newWidth, newHeight;
		glfwGetFramebufferSize(window, &newWidth, &newHeight);

		if(newWidth != width || newHeight != height) {
			int oldWidth = width, oldHeight = height;
			width = newWidth;
			height = newHeight;
			foreach(cb; d_resizeCallBacks) {
				cb(vec2i(oldWidth, oldHeight), vec2i(newWidth, newHeight));
			}
		}

		if(glfwWindowShouldClose(window))
			shouldCloseWindow = true;

		if(setCursorPosition) {
			glfwSetCursorPos(window, cursorPosition.x, cursorPosition.y);
			setCursorPosition = false;
		}
	}

	bool shouldClose() {
		if(shouldCloseWindow)
			switchScreen(new EmptyScreen);
		return shouldCloseWindow;
	}

	nothrow void shouldClose(bool shouldclose) {
		shouldCloseWindow = shouldclose;
	}

	void close(bool endGLFW = true) {
		if(visible == false)
			return;

		glfwDestroyWindow(window);
		visible = false;

		if(endGLFW == true)
			glfwTerminate();
	}

	@property vec2i screenDimension() {
		return vec2i(width, height);
	}

	void setMousePosition(double x, double y) nothrow {
		cursorPosition.x = x;
		cursorPosition.y = y;
		setCursorPosition = true;
	}
}
