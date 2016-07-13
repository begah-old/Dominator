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

private alias f_keyCallback = void function(int key, int action, int mods) nothrow;
private alias f_characterCallback = void function(uint character) nothrow;
private alias f_cursorCallBack = void function(double x, double y) nothrow;
private alias f_mouseCallBack = void function(int button, int action) nothrow;

private alias d_keyCallback = void delegate(int key, int action, int mods) nothrow;
private alias d_characterCallback = void delegate(uint character) nothrow;
private alias d_cursorCallBack = void delegate(double x, double y) nothrow;
private alias d_mouseCallBack = void delegate(int button, int action) nothrow;

class Window {
	GLFWwindow *window;
	bool visible, shouldCloseWindow;

	string title;
	int width, height;
	int currentFps = 60, averageFps = 60;

	f_keyCallback[] f_keyCallbacks; d_keyCallback[] d_keyCallbacks;
	f_characterCallback[] f_characterCallbacks; d_characterCallback[] d_characterCallbacks;
	f_cursorCallBack[] f_cursorCallbacks, f_scrollCallbacks; d_cursorCallBack[] d_cursorCallbacks, d_scrollCallbacks;
	f_mouseCallBack[] f_mouseCallbacks; d_mouseCallBack[] d_mouseCallbacks;

	vec2d cursorPosition;
	bool setCursorPosition = false;

	private Timer timer;

	nothrow @trusted :

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
		glfwSetCursorPosCallback(window, &CCursorCallBack);
		glfwSetScrollCallback(window, &CScrollCallBack);

		glfwMakeContextCurrent(window);

		if(setCursorPosition) {
			glfwSetCursorPos(window, cursorPosition.x, cursorPosition.y);
			setCursorPosition = false;
		}

		try {
			DerelictGL3.reload();
		} catch(Exception ex) {
			abort(ex.msg);
		}

		visible = true;

		Window_List[cast(long)window] = this;

		timer = Timer();
	}

	void addCallBack(f_keyCallback cb) {
		this.f_keyCallbacks ~= cb;
	}
	void addCallBack(f_characterCallback cb) {
		this.f_characterCallbacks ~= cb;
	}

	/* isScroll : True for scroll callback, False for mouse position callback */
	void addCallBack(f_cursorCallBack cb, bool isScroll = false) {
		if(!isScroll) this.f_cursorCallbacks ~= cb;
		else this.f_scrollCallbacks ~= cb;
	}
	void addCallBack(f_mouseCallBack cb) {
		this.f_mouseCallbacks ~= cb;
	}
	void addCallBack(d_keyCallback cb) {
		this.d_keyCallbacks ~= cb;
	}
	void addCallBack(d_characterCallback cb) {
		this.d_characterCallbacks ~= cb;
	}

	/* isScroll : True for scroll callback, False for mouse position callback */
	void addCallBack(d_cursorCallBack cb, bool isScroll = false) {
		if(!isScroll) this.d_cursorCallbacks ~= cb;
		else this.d_scrollCallbacks ~= cb;
	}
	void addCallBack(d_mouseCallBack cb) {
		this.d_mouseCallbacks ~= cb;
	}

	private void KeyCallBack(int key, int action, int mods) nothrow {
		foreach(cb; this.f_keyCallbacks) {
			cb(key, action, mods);
		}foreach(cb; this.d_keyCallbacks) {
			cb(key, action, mods);
		}

		if(key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
			this.shouldClose(true);
		}
	}

	private void CharacterCallBack(uint character) nothrow {
		foreach(cb; this.f_characterCallbacks) {
			cb(character);
		}foreach(cb; this.d_characterCallbacks) {
			cb(character);

		}
	}

	private void CursorCallBack(double x, double y) nothrow {
		cursorPosition.x = x; cursorPosition.y = y;
		foreach(cb; this.f_cursorCallbacks) {
			cb(x, y);
		}foreach(cb; this.d_cursorCallbacks) {
			cb(x, y);
		}
	}

	private void ScrollCallback(double x, double y) nothrow {
		foreach(cb; this.f_scrollCallbacks) {
			cb(x, y);
		}foreach(cb; this.d_scrollCallbacks) {
			cb(x, y);
		}
	}

	private void MouseCallBack(int button, int action, int mods) nothrow {
		foreach(cb; this.f_mouseCallbacks) {
			cb(button, action);
		}foreach(cb; this.d_mouseCallbacks) {
			cb(button, action);
		}
	}

	private int frameCount = 0;
	private long frameFpsCount = 0;

	void refresh() {
		if(visible == false)
			return;

		long time = timer.elapsedTime();
		timer.reset();

		if(time > 0) {
			currentFps = cast(int) (1000 / time);
			frameCount++;
			frameFpsCount += currentFps;
		}

		if(frameCount == 60) {
			averageFps = cast(int) (frameFpsCount / 60);
			frameCount = frameFpsCount = 0;
		}

		glfwSwapBuffers(window);
		glfwPollEvents();

		glfwGetFramebufferSize(window, &width, &height);

		if(glfwWindowShouldClose(window))
			shouldCloseWindow = true;

		if(setCursorPosition) {
			glfwSetCursorPos(window, cursorPosition.x, cursorPosition.y);
			setCursorPosition = false;
		}
	}

	nothrow bool shouldClose() {
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
