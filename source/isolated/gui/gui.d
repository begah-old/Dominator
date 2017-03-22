module isolated.gui.gui;

import std.meta;

import isolated.math;
import isolated.graphics.texture;
import isolated.graphics.utils.opengl;
import isolated.graphics.mesh;
import isolated.graphics.vertexattribute;
import isolated.graphics.g3d.model;
import isolated.graphics.g3d.modelinstance;
import isolated.graphics.shader;
import isolated.window;
import isolated.utils.logger;
import isolated.gui.font;

import shared_memory;

class GuiElement {
	enum Value_Type {
		ABSOLUTE,
		PERCENTAGE,
	}

	union Value {
		vec2 percentage;
		vec2i absolute;
	}

	enum Anchor {
		None = 0,
		Left = 1, 
		Right = 2,
		Up = 4,
		Down = 8
	}

	private Anchor _anchor;
	private int _horizontalAnchor, _verticalAnchor;

	Value_Type Position_Type;
	Value Position;

	Value_Type Size_Type;
	Value Size;

	void *userData;
	bool visible = true;

	vec2 glPosition, glSize, glScale;

	protected mat4 glTransform;

	static private bool isRightType(Value1)(Value1 v, Value_Type type) {
		if(type == Value_Type.ABSOLUTE)
			return is(typeof(v) == vec2i);
		if(type == Value_Type.PERCENTAGE)
			return is(typeof(v) == vec2);
		return false;
	}

	// Position and size of element, glScale is the ratio needed to have to display on current sized screen at desired dimensions
	this(Value1, Value2)(Value1 position, Value2 size, Value_Type positionType, Value_Type sizeType, vec2 glScale = vec2(1)) {
		assert(isRightType(Value1.init, positionType));
		assert(isRightType(Value2.init, sizeType));
		static if(is(typeof(position) == vec2)) { Position.percentage = position; } else { Position.absolute = position; }
		static if(is(typeof(position) == vec2)) { Size.percentage = size; } else { Size.absolute = size; }
		Position_Type = positionType;
		Size_Type = sizeType;

		if(positionType == Value_Type.ABSOLUTE && sizeType == Value_Type.ABSOLUTE) {
			updateSize();
			this.glScale = vec2(glScale.x / glSize.x, glScale.y / glSize.y);
			updateMatrix();
		}
	}

	bool cursorEvent(double x, double y) {
		return false;
	}

	bool mouseEvent(double x, double y, int button, int action) {
		return false;
	}

	bool keyEvent(int key, int action, int mods) {
		return false;
	}

	bool characterEvent(uint character) {
		return false;
	}

	private void updateSize() {
		if(Size_Type == Value_Type.ABSOLUTE)
			glSize = vec2(Size.absolute.x * 2.0f / cast(float)mainWindow.width, Size.absolute.y * 2.0f / cast(float)mainWindow.height);
		else
			glSize = vec2(Size.absolute.x * 2.0f, Size.absolute.y * 2.0f);
	}

	private void updatePosition() {
		if(Position_Type == Value_Type.ABSOLUTE)
			glPosition = vec2(Position.absolute.x * 2.0f / mainWindow.width - 1.0f + glSize.x / 2.0f, Position.absolute.y * 2.0f / mainWindow.height - 1.0f + glSize.y / 2.0f);
		else
			glPosition = vec2(Position.percentage.x * 2.0f - 1.0f, Position.percentage.y * 2.0f - 1.0f);
	}

	void updateMatrix() {
		updateSize();
		updatePosition();

		// Transformation matrix of element in opengl units. The z value is to control the opaqueness of the element : -1 is opaque and 1 is completly transparent
		glTransform = calculateTransformation(vec3(glPosition, -1.0f), vec3(0), vec3(glSize.x * glScale.x, glSize.y * glScale.y, 1));
	}

	void resize(vec2i previous, vec2i current) {
		if(_anchor & Anchor.Right)
			setAbsoluteValue(&Position, Position_Type, vec2i(current.x - _horizontalAnchor, valueAbsolute(Position, Position_Type).y));
		if(_anchor & Anchor.Up) {
			setAbsoluteValue(&Position, Position_Type, vec2i(valueAbsolute(Position, Position_Type).x, current.y - _verticalAnchor));
		}

		updateMatrix();
	}

	void moveBy(vec2i amount) {
		if(amount == vec2i(0)) return;
		if(Position_Type == Value_Type.ABSOLUTE)
			Position.absolute += amount;
		else
			Position.percentage += vec2(amount.x / cast(float)mainWindow.width, amount.y / cast(float)mainWindow.height);

		updateMatrix();
	}

	static vec2i valueAbsolute(Value value, Value_Type type) {
		if(type == Value_Type.ABSOLUTE)
			return value.absolute;
		else
			return vec2i(cast(int)round(value.percentage.x * mainWindow.width), cast(int)round(value.percentage.y * mainWindow.height));
	}

	void setAbsoluteValue(Value *value, Value_Type type, vec2i newValue) {
		if(type == Value_Type.ABSOLUTE)
			value.absolute = newValue;
		else
			value.percentage = vec2(cast(float)newValue.x / mainWindow.width, cast(float)newValue.y / mainWindow.height);
	}

	GuiElement anchor(Anchor anchor) {
		_anchor = anchor;
		updateAnchor();
		return this;
	}

	void updateAnchor() {
		if(_anchor & Anchor.Left)
			_horizontalAnchor = valueAbsolute(Position, Position_Type).x;
		else if(_anchor & Anchor.Right)
			_horizontalAnchor = mainWindow.width - valueAbsolute(Position, Position_Type).x;

		if(_anchor & Anchor.Down)
			_verticalAnchor = valueAbsolute(Position, Position_Type).y;
		else if(_anchor & Anchor.Up)
			_verticalAnchor = mainWindow.height - valueAbsolute(Position, Position_Type).y;
	}

	abstract void render();
}

class Image : GuiElement {
	static __gshared Shader shader = null;
	static __gshared Mesh mesh;
	static __gshared uint count;

	Texture texture;

	this(int x, int y, Texture texture, float ratio = 1.0f) {
		if(shader is null) {
			shader = new Shader("gui_image");
			mesh = Mesh.Square(-0.5f, -0.5f, 1, 1, 0, VertexAttribute.Usage.Position | VertexAttribute.Usage.TextureCoordinates);
			mesh.generate(shader);
		}

		this.texture = texture;
	
		vec2i size = vec2i(cast(int)round(texture.width * ratio), cast(int)round(texture.height * ratio));
		super(vec2i(x, y), size, Value_Type.ABSOLUTE, Value_Type.ABSOLUTE, vec2(size.x * 2.0f / mainWindow.width, size.y * 2.0f / mainWindow.height));

		count++;
	}

	override void render() {
		if(!visible) return;

		shader.bind();
		shader.uniform(shader.textureSamplers[0], 0);
		texture.bind();

		shader.uniform("uTransform", glTransform);

		glBindVertexArray(mesh.vao);
		glDrawArrays(GL_TRIANGLES, 0, cast(GLint)mesh.vertexCount);
		glBindVertexArray(0);

		texture.unbind();
		shader.unbind();
	}

	~this() {
		count--;

		if(count == 0) {
			// Destroy shader and mesh
		}
	}
}

class Text : GuiElement {
	Mesh mesh;
	FontManager fontManager;
	Color color;
	string text;
	int availableHeight;

	Texture fontAtlas;
	float widthRatio, heightRatio;

	this(int x, int y, int maxWidth, int availableHeight, string str, float widthRatio = 1.0f, float heightRatio = 1.0f) {
		this.availableHeight = availableHeight;
		this.widthRatio = widthRatio;
		this.heightRatio = heightRatio;
		vec2i size;
		mesh = FontManager.current.renderText(str, maxWidth, availableHeight, size);
		fontAtlas = FontManager.current.getFont(availableHeight).atlas;
		fontManager = FontManager.current;
		color = Color.Black;
		text = str;

		super(vec2i(x, y), vec2i(cast(int)(size.x * widthRatio), cast(int)(size.y * heightRatio)), Value_Type.ABSOLUTE, Value_Type.ABSOLUTE, vec2(widthRatio, heightRatio));
	}

	static vec2i calculateDimension(string str, int availaibleHeight, FontManager manager = FontManager.current) {
		return manager.dimensionText(str, availaibleHeight);
	}

	override void render() {
		if(!visible) return;

		Font.shader.bind();
		Font.shader.uniform(Font.shader.textureSamplers[0], 0);
		fontAtlas.bind();

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		Font.shader.uniform("uTransform", glTransform);
		Font.shader.uniform("textColor", color);

		glBindVertexArray(mesh.vao);
		glDrawArrays(GL_TRIANGLES, 0, cast(GLint)mesh.vertexCount);
		glBindVertexArray(0);

		fontAtlas.unbind();
		Font.shader.unbind();

		glDisable(GL_BLEND);
	}

	void resize(int availableHeight, vec2i previous, vec2i current, float widthRatio = 1.0f, float heightRatio = 1.0f, int textWidth = -1) {
		vec2i size;
		mesh.destroy();
		mesh = fontManager.renderText(text, textWidth, availableHeight, size);
		this.availableHeight = availableHeight;
		this.widthRatio = widthRatio;
		this.heightRatio = heightRatio;
		this.fontAtlas = fontManager.getFont(availableHeight).atlas;

		Size.absolute = vec2i(cast(int)(size.x * widthRatio), cast(int)(size.y * heightRatio));
		updateSize();

		glScale = vec2(widthRatio / glSize.x, heightRatio / glSize.y);

		updateMatrix();
	}

	void changeText(string newText, int maxTextWidth = -1, float widthRatio = 1.0f, float heightRatio = 1.0f) {
		text = newText;
		resize(availableHeight, mainWindow.screenDimension, mainWindow.screenDimension, widthRatio, heightRatio, maxTextWidth);
	}
}

class Box : GuiElement {
	static __gshared Shader shader;
	static __gshared Model model;

	ModelInstance instance;
	
	private {
		bool dirtyColor = false;
		Color lbColor, rbColor, luColor, ruColor; // l = left corner, r = right corner, u = upper corner, l = lower corner
	}

	this(int x, int y, int width, int height, Color leftBottom, Color rightBottom = Color.init, Color rightTop = Color.init, Color leftTop = Color.init) {
		this(vec2i(x,y), vec2i(width, height), leftBottom, rightBottom, rightTop, leftTop);
	}

	this(vec2i pos, vec2i size, Color leftBottom, Color rightBottom = Color.init, Color rightTop = Color.init, Color leftTop = Color.init) {
		super(pos, size, Value_Type.ABSOLUTE, Value_Type.ABSOLUTE, vec2(size.x / (mainWindow.width / 2.0f), size.y / (mainWindow.height / 2.0f)));

		if(shader is null) {
			shader = new Shader("gui_box");
			model = new Model(Mesh.Square(-0.5f, -0.5f, 1, 1, 0, VertexAttribute.Usage.Position | VertexAttribute.Usage.ColorPacked), shader);
		}

		if(rightBottom == Color.init) {
			lbColor = rbColor = luColor = ruColor = leftBottom;
		} else {
			lbColor = leftBottom;
			rbColor = rightBottom;
			luColor = leftTop;
			ruColor = rightTop;
		}

		instance = new ModelInstance(model);
		instance.changeVertexInfo(VertexAttribute.Usage.ColorPacked, true, [lbColor.r / 255.0f, lbColor.g / 255.0f, lbColor.b / 255.0f, lbColor.a / 255.0f, rbColor.r / 255.0f, rbColor.g / 255.0f, rbColor.b / 255.0f, rbColor.a / 255.0f, ruColor.r / 255.0f, ruColor.g / 255.0f, ruColor.b / 255.0f, ruColor.a / 255.0f, lbColor.r / 255.0f, lbColor.g / 255.0f, lbColor.b / 255.0f, lbColor.a / 255.0f, ruColor.r / 255.0f, ruColor.g / 255.0f, ruColor.b / 255.0f, ruColor.a / 255.0f, luColor.r / 255.0f, luColor.g / 255.0f, luColor.b / 255.0f, luColor.a / 255.0f]);
		instance.setTransformation(glTransform);
	}

	override void render() {
		if(!visible) return;

		if(dirtyColor) {
			instance.vertexInfoSet(VertexAttribute.Usage.ColorPacked, 0, 6, [lbColor.r / 255.0f, lbColor.g / 255.0f, lbColor.b / 255.0f, lbColor.a / 255.0f, rbColor.r / 255.0f, rbColor.g / 255.0f, rbColor.b / 255.0f, rbColor.a / 255.0f, ruColor.r / 255.0f, ruColor.g / 255.0f, ruColor.b / 255.0f, ruColor.a / 255.0f, lbColor.r / 255.0f, lbColor.g / 255.0f, lbColor.b / 255.0f, lbColor.a / 255.0f, ruColor.r / 255.0f, ruColor.g / 255.0f, ruColor.b / 255.0f, ruColor.a / 255.0f, luColor.r / 255.0f, luColor.g / 255.0f, luColor.b / 255.0f, luColor.a / 255.0f]);
			dirtyColor = false;
		}

		shader.bind();

		instance.setTransformation(glTransform);

		model.begin();
		instance.render();
		model.end();

		shader.unbind();
	}

	void color(Color color) @property {
		lbColor = rbColor = luColor = ruColor = color;
		dirtyColor = true;
	}

	Color color() @property {
		return lbColor;
	}
}

class Label : GuiElement {
	Box box;

	Text text = null;
	Image image = null;

	// Position of gui element in label
	enum Layout {
		None = 0,
		Left = 1,
		Center = 2,
		Right = 4
	}
	Layout textLayout = Layout.None, imageLayout = Layout.None;
	uint leftOffset = 5, rightOffset = 5;

	this(int x, int y, int width, int height, string str, Layout textLayout = Layout.Center) {
		box = new Box(x, y, width, height, Color.White);

		this.textLayout = Layout.Center;

		float ratio, g; int textWidth;
		vec2i pos = calculateElementPosition(str, null, ratio, g, textWidth)[0];

		text = new Text(pos.x, pos.y, textWidth, height, str, ratio, ratio);

		super(vec2i(x, y), vec2i(width, height), Value_Type.ABSOLUTE, Value_Type.ABSOLUTE);
	}

	this(int x, int y, int width, int height, Texture texture, Layout imageLayout = Layout.Center) {
		box = new Box(x, y, width, height, Color.White);

		this.imageLayout = imageLayout;
		leftOffset = rightOffset = 0;

		float ratio, g; int textWidth;
		vec2i pos = calculateElementPosition(null, texture, g, ratio, textWidth)[1];

		image = new Image(pos.x, pos.y, texture, ratio);

		super(vec2i(x, y), vec2i(width, height), Value_Type.ABSOLUTE, Value_Type.ABSOLUTE);
	}

	this(int x, int y, int width, int height, string str, Texture texture, Layout textLayout = Layout.Left, Layout imageLayout = Layout.Left) {
		box = new Box(x, y, width, height, Color.White);

		this.textLayout = textLayout;
		this.imageLayout = imageLayout;

		float ratio1, ratio2; int textWidth;
		vec2i[2] pos = calculateElementPosition(str, texture, ratio1, ratio2, textWidth);

		text = new Text(pos[0].x, pos[0].y, textWidth, height, str, ratio1, ratio1);
		image = new Image(pos[1].x, pos[1].y, texture, ratio2);

		super(vec2i(x, y), vec2i(width, height), Value_Type.ABSOLUTE, Value_Type.ABSOLUTE);
	}

	Label backgroundColor(Color color) @property {
		box.color = color;
		return this;
	}

	Label textColor(Color color) @property {
		text.color = color;
		return this;
	}

	void changeText(string newText) {
		float ratio1, ratio2; int textWidth;
		vec2i[2] pos = calculateElementPosition(newText, image is null ? null : image.texture, ratio1, ratio2, textWidth);
		text.changeText(newText, textWidth, ratio1, ratio1);
		text.Position.absolute = pos[0];
		text.updateMatrix();

		if(image !is null) {
			image.Position.absolute = pos[1];
			image.updateMatrix();
		}
	}

	vec2i[2] calculateElementPosition(string str, Texture texture, out float ratio1, out float ratio2, out int textWidth) {
		int x = box.Position.absolute.x + leftOffset, y = box.Position.absolute.y, width = box.Size.absolute.x - leftOffset - rightOffset, height = box.Size.absolute.y;
		vec2i[2] positions;

		vec2i textDimensions(ref int yy) {
			vec2i dimension = Text.calculateDimension(str, height); // Calculate vertical position of text
			ratio1 = cast(float)height / dimension.y;
			yy = cast(int)round(max(y, y + height - dimension.y + cast(float)FontManager.current.getFont(height).textMinY / dimension.y * height));
			textWidth = -1;

			if(cast(int)round(dimension.x * ratio1) > width) {
				textWidth = cast(int)round(width / ratio1);
				return vec2i(width, cast(int)round(dimension.y * ratio1));
			} else
				return vec2i(cast(int)round(dimension.x * ratio1), cast(int)round(dimension.y * ratio1));
		}

		// Left layout
		if(imageLayout == Layout.Left && texture !is null && width > 0) {
			int newWidth = min(texture.width, width), newHeight = min(texture.height, height);
			ratio2 = min(cast(float)newWidth / texture.width, cast(float)newHeight / texture.height);
			int yy = cast(int)round(y + height / 2.0 - texture.height * ratio2 / 2.0f);
			positions[1] = vec2i(x, yy);
			x += cast(int)round(texture.width * ratio2);
			width -= cast(int)round(texture.width * ratio2);
		}
		if(textLayout == Layout.Left && str !is null && width > 0) {
			Logger.info(str);
			int yy;
			vec2i dim = textDimensions(yy);
			positions[0] = vec2i(x, yy);
			x += dim.x;
			width -= dim.x;
		}

		// Center layout
		if(imageLayout == Layout.Center && texture !is null && width > 0) {
			int newWidth = min(texture.width, width), newHeight = min(texture.height, height);
			ratio2 = min(cast(float)newWidth / texture.width, cast(float)newHeight / texture.height);
			int yy = cast(int)round(y + height / 2.0 - texture.height * ratio2 / 2.0);
			positions[1] = vec2i(cast(int)round(x + width / 2.0 - texture.width * ratio2 / 2.0), yy);
			x += cast(int)round(width / 2.0 + texture.width * ratio2 / 2.0);
			width -= cast(int)round(width / 2.0 + texture.width * ratio2 / 2.0);
		}
		if(textLayout == Layout.Center && str !is null && width > 0) {
			int yy;
			vec2i dim = textDimensions(yy);
			positions[0] = vec2i(cast(int)round(x + width / 2.0 - dim.x / 2.0), yy);
			if(dim.x >= width) {
				x += dim.x;
				width = 0;
			} else {
				x += cast(int)round(width / 2.0 + dim.x / 2.0);
				width -= cast(int)round(width / 2.0 + dim.x / 2.0);
			}
		}

		// Right layout
		if(imageLayout == Layout.Right && texture !is null && width > 0) {
			int newWidth = min(texture.width, width), newHeight = min(texture.height, height);
			ratio2 = min(cast(float)newWidth / texture.width, cast(float)newHeight / texture.height);
			int yy = cast(int)round(y + height / 2.0 - texture.height * ratio2 / 2.0f);
			positions[1] = vec2i(cast(int)round(x + width - texture.width * ratio2), yy);
			x += cast(int)round(width - texture.width * ratio2);
			width = 0;
		}
		if(textLayout == Layout.Right && str !is null && width > 0) {
			int yy;
			vec2i dim = textDimensions(yy);
			positions[0] = vec2i(cast(int)round(x + width - dim.x), yy);
			x += cast(int)round(width - dim.x);
			width = 0;
		}

		return positions;
	}

	override void render() {
		if(!visible) return;

		box.render();
		if(text !is null)text.render();
		if(image !is null)image.render();
	}

	override void moveBy(vec2i amount) {
		box.moveBy(amount);
		if(text !is null)text.moveBy(amount);
		if(image !is null)image.moveBy(amount);
		super.moveBy(amount);
	}

	override void updateMatrix() {
		vec2i translation = valueAbsolute(Position, Position_Type) - box.Position.absolute;

		box.moveBy(translation);
		if(text !is null)text.moveBy(translation);
		if(image !is null)image.moveBy(translation);
		super.updateMatrix();
	}

	override void resize(vec2i previous, vec2i current) {
		box.resize(previous, current);
		
		Position = box.Position;
		Size = box.Size;

		float r1, r2; int textWidth;
		vec2i[] positions = calculateElementPosition(text !is null ? text.text : null, image !is null ? image.texture : null, r1, r2, textWidth);

		if(text !is null) {
			text.resize(Size.absolute.y, current, previous, r1, r1, textWidth);
			text.Position.absolute = positions[0];
			text.updateMatrix();
		}
		if(image !is null) {
			image.resize(previous, current);
			image.Position.absolute = positions[1];
			image.updateMatrix();
		}
	}
}

class Button : Label {
	enum State {
		Idle,
		Hover,
		Down,
		Disabled
	}

	State state;
	private Color idle, hover, down;
	private Texture idleTexture, hoverTexture, downTexture;

	alias CallBack = void delegate(Button, void*);
	CallBack enter = null, exit = null, pressed = null, released = null; 

	this(int x, int y, int width, int height, string str, Layout textPosition = Layout.Center) {
		state = State.Idle;
		idle = Color.White;
		hover = Color.Gray;
		down = Color(100, 100, 100, 255);

		super(x, y, width, height, str, textPosition);
	}

	this(int x, int y, int width, int height, Texture texture, Layout imageLayout = Layout.Center) {
		state = State.Idle;
		idle = Color.White;
		hover = Color.Gray;
		down = Color(100, 100, 100, 255);

		idleTexture = hoverTexture = downTexture = texture;

		super(x, y, width, height, texture, imageLayout);
	}

	this(int x, int y, int width, int height, Texture[3] texture, Layout imageLayout = Layout.Center) {
		state = State.Idle;
		idle = Color.White;
		hover = Color.Gray;
		down = Color(100, 100, 100, 255);

		idleTexture = texture[0];
		hoverTexture = texture[1];
		downTexture = texture[2];

		super(x, y, width, height, texture[0], imageLayout);
	}

	this(int x, int y, int width, int height, string str, Texture[3] texture, Layout textLayout = Layout.Left, Layout imageLayout = Layout.Left) {
		state = State.Idle;
		idle = Color.White;
		hover = Color.Gray;
		down = Color(100, 100, 100, 255);

		idleTexture = texture[0];
		hoverTexture = texture[1];
		downTexture = texture[2];

		super(x, y, width, height, str, texture[0], textLayout, imageLayout);
	}

	override Button backgroundColor(Color color) @property {
		return idleColor(color);
	}

	override Button textColor(Color color) @property {
		text.color = color;
		return this;
	}

	Button idleColor(Color c) {
		if(state == State.Idle)
			box.color(c);
		this.idle = c;
		return this;
	}
	Button hoverColor(Color c) {
		if(state == State.Hover)
			box.color(c);
		this.hover = c;
		return this;
	}
	Button downColor(Color c) {
		if(state == State.Down || state == State.Disabled)
			box.color(c);
		this.down = c;
		return this;
	}

	Button setTextures(Texture[3] textures) {
		return setTextures(textures[0], textures[1], textures[2]);
	}

	Button setTextures(Texture idle, Texture hover, Texture down) {
		this.idleTexture = idle;
		this.hoverTexture = hover;
		this.downTexture = down;

		return this;
	}

	void changeState(State newState) {
		if(state == newState)
			return;
		switch(newState) {
		case State.Idle:
			box.color(idle);
			if(image !is null)image.texture = idleTexture;
			break;
		case State.Hover:
			box.color(hover);
			if(image !is null)image.texture = hoverTexture;
			break;
		case State.Down:
		case State.Disabled:
			box.color(down);
			if(image !is null)image.texture = downTexture;
			break;
		default: break;
		}

		state = newState;
	}

	void setState(State newState) {
		if(state == newState) return;
		changeState(newState);

		if(released !is null && newState == State.Idle && state == State.Down)
			released(this, userData);
		else if(pressed !is null && newState == State.Down)
			pressed(this, userData);
	}

	override bool cursorEvent(double x, double y) {
		if(state == State.Disabled  || visible == false)
			return false;

		if(pointInSquare(vec2(x, y), Position.absolute, Size.absolute)) {
			if(state == State.Idle) {
				changeState(State.Hover);
				if(enter !is null)
					enter(this, userData);
			}
			return true;
		} else if(state == State.Hover) {
			changeState(State.Idle);

			if(exit !is null)
				exit(this, userData);
		}
		return false;
	}

	override bool mouseEvent(double x, double y, int button, int action) {
		if(state == State.Disabled || visible == false)
			return false;

		if(pointInSquare(vec2(x, y), Position.absolute, Size.absolute)) {
			if(!action && state == State.Down) {
				changeState(State.Hover);
				if(released !is null)
					released(this, userData);
			}
			if(action && (state == State.Hover || state == State.Idle)) {
				changeState(State.Down);

				if(pressed !is null)
					pressed(this, userData);
			}
			return true;
		} else {
			if(!action && state == State.Down) {
				changeState(State.Idle);

				if(released !is null)
					released(this, userData);
			}
		}
		return false;
	}

	override void render() {
		super.render();
	}
}

class ToggleableButton : Button {
	CallBack toggled = null;
	private Texture hoverDownTexture = null;

	this(int x, int y, int width, int height, string str, Layout textPosition = Layout.Center) {
		super(x, y, width, height, str, textPosition);
	}

	this(int x, int y, int width, int height, Texture texture, Layout imageLayout = Layout.Center) {
		super(x, y, width, height, texture, imageLayout);
	}

	this(int x, int y, int width, int height, Texture[4] texture, Layout imageLayout = Layout.Center) {
		leftOffset = 0;
		super(x, y, width, height, texture[0..3], imageLayout);
		hoverDownTexture = texture[3];
	}

	this(int x, int y, int width, int height, string str, Texture[4] texture, Layout textLayout = Layout.Left, Layout imageLayout = Layout.Left) {
		leftOffset = 0;
		super(x, y, width, height, str, texture[0..3], textLayout, imageLayout);
		hoverDownTexture = texture[3];
	}

	override void setState(State newState) {
		State oldState = state;
		super.setState(newState);

		if(toggled !is null && newState != oldState)
			toggled(this, userData);
	}

	override bool cursorEvent(double x, double y) {
		if(state == State.Disabled  || visible == false)
			return false;

		if(pointInSquare(vec2(x, y), Position.absolute, Size.absolute)) {
			if(state == State.Idle) {
				changeState(State.Hover);
				if(enter !is null)
					enter(this, userData);
			}
			if(state == State.Down) {
				if(image !is null) image.texture = hoverDownTexture;
			}
			return true;
		} else if(state == State.Hover) {
			changeState(State.Idle);

			if(exit !is null)
				exit(this, userData);
		} else if(state == State.Down) {
			if(image !is null) image.texture = downTexture;
		}
		return false;
	}

	override bool mouseEvent(double x, double y, int button, int action) {
		if(state == State.Disabled || visible == false)
			return false;

		if(action && pointInSquare(vec2(x, y), Position.absolute, Size.absolute)) {
			if((state == State.Hover || state == State.Idle)) {
				changeState(State.Down);
				if(image !is null) image.texture = hoverDownTexture;

				if(pressed !is null)
					pressed(this, userData);
				if(toggled !is null)
					toggled(this, userData);
			} else if(state == State.Down) {
				changeState(State.Hover);

				if(released !is null)
					released(this, userData);
				if(toggled !is null)
					toggled(this, userData);
			}
			return true;
		}
		return false;
	}
}

class Textbox : Button {
	string currentText, defaultText, labelText;

	private size_t _characterLimit = 15;

	this(int x, int y, int width, int height, string label, string defaultText = "", Layout textPosition = Layout.Left) {
		this.defaultText = defaultText;
		this.labelText = label;
		this.currentText = "";
		super(x, y, width, height, label ~ defaultText, textPosition);
	}

	override bool mouseEvent(double x, double y, int button, int action) {
		if(state == State.Disabled || visible == false)
			return false;

		if(pointInSquare(vec2(x, y), Position.absolute, Size.absolute)) {
			if(action && (state == State.Hover || state == State.Idle)) {
				changeState(State.Down);

				if(pressed !is null)
					pressed(this, userData);
			}
			return true;
		} else {
			if(state == State.Down) {
				changeState(State.Idle);

				if(released !is null)
					released(this, userData);
			}
		}
		return false;
	}

	override bool keyEvent(int key, int action, int mods) {
		if(state != State.Down || visible == false) return false;

		import isolated.window;

		if(action && key == GLFW_KEY_BACKSPACE && currentText.length) {
			currentText.length--;
			if(currentText.length == 0) {
				changeText(labelText ~ defaultText);
			} else {
				changeText(labelText ~ currentText);
			}
			return true;
		} else if(action && key == GLFW_KEY_ENTER && state == State.Down) {
			changeState(State.Idle);

			if(released !is null)
				released(this, userData);
		}
		return false;
	}

	override bool characterEvent(uint character) {
		if(state != State.Down || visible == false) return false;

		if(currentText.length >= _characterLimit)
			return false;

		currentText ~= cast(char)character;
		changeText(labelText ~ currentText);

		return true;
	}

	Textbox characterLimit(size_t limit) {
		_characterLimit = limit;
		return this;
	}

	size_t characterLimit() {
		return _characterLimit;
	}

	string label() {
		return labelText;
	}

	string value() {
		if(currentText.length)
			return currentText;
		else
			return defaultText;
	}

	void value(string s) {
		setText(null, null, s);
	}

	void setText(string labelText, string defaultText = null, string currentText = null) {
		if(labelText !is null)
			this.labelText = labelText;
		if(defaultText !is null)
			this.defaultText = defaultText;
		if(currentText !is null)
			this.currentText = currentText;

		if(this.currentText.length == 0) {
			changeText(this.labelText ~ this.defaultText);
		} else {
			changeText(this.labelText ~ this.currentText);
		}
	}
}

class Panel : GuiElement {
	GuiElement[] elements;
	Box background;

	// Coordinates of the top-left corner
	uint minWidth, minHeight;
	uint maxWidth, maxHeight;
	uint totalWidth, totalHeight;

	// elementOffset is the distance between two elements
	uint leftOffset, topOffset, elementOffset;

	// X and Y coordinates are of the top-left corner
	this(int x, int y, uint minWidth = 0, uint minHeight = 0) {
		this.minWidth = minWidth;
		this.minHeight = minHeight;

		super(vec2i(x,y - minHeight), vec2i(minWidth, minHeight), Value_Type.ABSOLUTE, Value_Type.ABSOLUTE);
		background = new Box(x, y - minHeight, minWidth, minHeight, Color.White);
	}

	void setMaximunSize(uint maxWidth, uint maxHeight) {
		this.maxWidth = maxWidth;
		this.maxHeight = maxHeight;
	}

	override void moveBy(vec2i amount) {
		if(amount == vec2i(0)) return;
		super.moveBy(amount);
		foreach(element; elements)
			element.moveBy(amount);
		background.moveBy(amount);
	}

	override GuiElement anchor(Anchor anchor) {
		return super.anchor(anchor);
	}

	protected void _addElement(GuiElement element) {
		if(valueAbsolute(element.Size, element.Size_Type).y + totalHeight > minHeight) {
			Position.absolute.y -= valueAbsolute(element.Size, element.Size_Type).y;
			Size.absolute.y += valueAbsolute(element.Size, element.Size_Type).y;
		}
		background.Position.absolute.y = Position.absolute.y;
		background.Size.absolute.y = Size.absolute.y;
		background.updateMatrix();
		totalHeight += valueAbsolute(element.Size, element.Size_Type).y;
		updateAnchor();

		elements ~= element;
	}

	GuiElement add(GuiElement element) {
		element.Position.absolute = vec2i(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - valueAbsolute(element.Size, element.Size_Type).y);
		element.Position_Type = Value_Type.ABSOLUTE;

		element.updateMatrix();
		_addElement(element);
		return element;
	}

	Label addLabel(string str, int width, int height, Label.Layout textLayout = Label.Layout.Center) {
		Label label = new Label(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - height, width, height, str, textLayout);
		_addElement(label);
		return label;
	}

	Button addButton(string str, int width, int height, Label.Layout textLayout = Label.Layout.Center) {
		Button button = new Button(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - height, width, height, str, textLayout);
		_addElement(button);
		return button;
	}

	Textbox addTextbox(string str, string defaultValue, int width, int height, Label.Layout textLayout = Label.Layout.Center) {
		Textbox textbox = new Textbox(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - height, width, height, str, defaultValue, textLayout);
		_addElement(textbox);
		return textbox;
	}

	DropDownMenu addDropDownMenu(string str, int width, int height) {
		DropDownMenu ddMenu = new DropDownMenu(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset, width, height, str);
		_addElement(ddMenu);
		return ddMenu;
	}

	EnumButton addEnumButton(string str, int width, int height) {
		EnumButton e = new EnumButton(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset, width, height, str);
		_addElement(e);
		return e;
	}

	override void render() {
		if(!visible) return;

		background.render();
		foreach(element; elements) {
			element.render();
		}
	}

	override bool cursorEvent(double x, double y) {
		if(!visible) return false;

		bool used = false;
		foreach(element; elements) {
			if(element.cursorEvent(x, y)) used = true;
		}
		return used;
	}

	override bool mouseEvent(double x, double y, int button, int action) {
		if(!visible || !pointInSquare(vec2d(x, y), background.Position.absolute, background.Size.absolute)) return false;

		bool used = false;
		int size, moveBy;
		foreach(i, element; elements) {
			element.moveBy(vec2i(0, moveBy));
			size = valueAbsolute(element.Size, element.Size_Type).y;
			if(element.mouseEvent(x, y, button, action)) used = true;

			if((size -= valueAbsolute(element.Size, element.Size_Type).y) != 0) {
				moveBy += size;
			}
		}
		if(moveBy != 0) {
			totalHeight -= moveBy;
			if(totalHeight < minHeight) {
				background.Size.absolute.y = minHeight;
				background.moveBy(vec2i(0, Size.absolute.y - minHeight));
			} else {
				background.Size.absolute.y -= moveBy;
				background.moveBy(vec2i(0, moveBy));
			}
			
			Position = background.Position;
			Size = background.Size;
			y = Position.absolute.y + Size.absolute.y;
			updateAnchor();
		}
		return used;
	}

	override bool keyEvent(int key, int action, int mods) {
		if(!visible) return false;

		foreach(element; elements) {
			if(element.keyEvent(key, action, mods)) return true;
		}
		return false;
	}

	override bool characterEvent(uint character) {
		if(!visible) return false;

		foreach(element; elements) {
			if(element.characterEvent(character)) return true;
		}
		return false;
	}

	override void resize(vec2i previous,vec2i current) {
		vec2i translation = Position.absolute;
		super.resize(previous,current);
		translation = Position.absolute - translation;

		background.Position = Position;
		background.Size = Size;
		background.updateMatrix();
		foreach(element; elements) {
			element.resize(previous, current);
			element.moveBy(translation);
		}
	}
}

class DropDownMenu : Panel {
	ToggleableButton toggleableButton;
	int elementHeight;

	// X and Y coordinates are of the top-left corner
	this(int x, int y, int width, int height, string labelName) {
		super(x, y, width, height);
		elementHeight = height;

		toggleableButton = new ToggleableButton(0, y - elementHeight, width, elementHeight, labelName, Texture.load!4("Gui_Builder/DropDownIcon.png"), Label.Layout.Center, Label.Layout.Left);
		toggleableButton.toggled = &buttonCallback;
		super.add(toggleableButton);
		toggleableButton.updateMatrix();
	}

	protected void buttonCallback(Button button, void* userData) {
		if(toggleableButton.state == Button.State.Down) {
			background.Size.absolute.y = totalHeight;
			background.Position.absolute.y = Position.absolute.y + Size.absolute.y - background.Size.absolute.y;
		} else {
			background.Size.absolute.y = toggleableButton.Size.absolute.y;
			background.Position.absolute.y = Position.absolute.y + Size.absolute.y - background.Size.absolute.y;
		}
		Position.absolute = background.Position.absolute;
		Size.absolute = background.Size.absolute;
		background.updateMatrix();
		updateAnchor();
	}

	override void _addElement(GuiElement element) {
		if(toggleableButton.state == Button.State.Down) {
			if(valueAbsolute(element.Size, element.Size_Type).y + totalHeight > minHeight) {
				Position.absolute.y -= valueAbsolute(element.Size, element.Size_Type).y;
				Size.absolute.y += valueAbsolute(element.Size, element.Size_Type).y;
			}
			background.Position.absolute.y = Position.absolute.y;
			background.Size.absolute.y = Size.absolute.y;
			background.updateMatrix();
			updateAnchor();
		}
		totalHeight += valueAbsolute(element.Size, element.Size_Type).y;
		elements ~= element;
	}

	override GuiElement add(GuiElement element) {
		element.Position.absolute = vec2i(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - valueAbsolute(element.Size, element.Size_Type).y);
		element.Position_Type = Value_Type.ABSOLUTE;

		element.updateMatrix();
		_addElement(element);
		return element;
	}

	override Label addLabel(string str, int width, int height, Label.Layout textLayout = Label.Layout.Center) {
		Label label = new Label(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - height, width, height, str, textLayout);
		_addElement(label);
		return label;
	}

	override Button addButton(string str, int width, int height, Label.Layout textLayout = Label.Layout.Center) {
		Button button = new Button(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - height, width, height, str, textLayout);
		_addElement(button);
		return button;
	}

	override Textbox addTextbox(string str, string defaultValue, int width, int height, Label.Layout textLayout = Label.Layout.Center) {
		Textbox textbox = new Textbox(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - height, width, height, str, defaultValue, textLayout);
		_addElement(textbox);
		return textbox;
	}

	override DropDownMenu addDropDownMenu(string str, int width, int height) {
		DropDownMenu ddMenu = new DropDownMenu(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset, width, height, str);
		_addElement(ddMenu);
		return ddMenu;
	}

	override EnumButton addEnumButton(string str, int width, int height) {
		EnumButton e = new EnumButton(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset, width, height, str);
		_addElement(e);
		return e;
	}

	override void render() {
		if(!visible) return;

		background.render();

		toggleableButton.render();
		if(toggleableButton.state == Button.State.Down)
			foreach(element; elements[1..$]) {
				element.render();
			}
	}

	override bool cursorEvent(double x, double y) {
		if(!visible) return false;

		bool used = false;
		if(toggleableButton.cursorEvent(x, y)) used = true;

		if(toggleableButton.state == Button.State.Down)
			foreach(element; elements[1..$]) {
				if(element.cursorEvent(x, y)) used = true;
			}
		return used;
	}

	bool used = false;
	override bool mouseEvent(double x, double y, int button, int action) {
		if(!visible || !pointInSquare(vec2d(x, y), background.Position.absolute, background.Size.absolute)) return false;

		bool used = false;
		if(toggleableButton.mouseEvent(x, y, button, action)) used = true;

		if(toggleableButton.state == Button.State.Down) {
			int size, moveBy;
			foreach(i, element; elements[1..$]) {
				element.moveBy(vec2i(0, moveBy));
				size = valueAbsolute(element.Size, element.Size_Type).y;
				if(element.mouseEvent(x, y, button, action)) used = true;

				if((size -= valueAbsolute(element.Size, element.Size_Type).y) != 0) {
					moveBy += size;
				}
			}

			if(moveBy != 0) {
				totalHeight -= moveBy;
				background.Size.absolute.y -= moveBy;
				background.moveBy(vec2i(0, moveBy));
				Position = background.Position;
				Size = background.Size;
				updateAnchor();
			}
		}
		return used;
	}

	override bool keyEvent(int key, int action, int mods) {
		if(!visible) return false;

		if(toggleableButton.keyEvent(key, action, mods)) return true;

		if(toggleableButton.state == Button.State.Down)
			foreach(element; elements[1..$]) {
				if(element.keyEvent(key, action, mods)) return true;
			}
		return false;
	}

	override bool characterEvent(uint character) {
		if(!visible) return false;

		if(toggleableButton.characterEvent(character)) return true;

		if(toggleableButton.state == Button.State.Down)
			foreach(element; elements[1..$]) {
				if(element.characterEvent(character)) return true;
			}
		return false;
	}
}

class EnumButton : DropDownMenu {
	size_t _value;

	alias valueChange = void delegate(EnumButton, size_t);
	valueChange callback;
	string label;

	// X and Y coordinates are of the top-left corner
	this(int x, int y, int width, int height, string enumName) {
		super(x, y, width, height, enumName);
		this.label = enumName;
	}

	EnumButton addEnum(string enumName, size_t enumValue) {
		ToggleableButton button = new ToggleableButton(Position.absolute.x + leftOffset, Position.absolute.y + Size.absolute.y - totalHeight - elementOffset - elementHeight, Size.absolute.x, elementHeight, enumName, Label.Layout.Center);
		button.userData = cast(void*)enumValue;
		button.pressed = &buttonPressed;
		button.released = &buttonReleased;

		if(elements.length == 1) {
			toggleableButton.changeText(label ~ enumName);
			_value = enumValue;
		}
		_addElement(button);
		return this;
	}

	void setEnum(size_t enumValue) {
		if(elements.length == 0 || _value == enumValue) return;

		bool found = false;
		foreach(element; elements) {
			if(cast(size_t)(cast(Button)element).userData == enumValue) {
				_value = enumValue;
				found = true;
				(cast(Button)element).setState(Button.State.Down);
				toggleableButton.changeText(label ~ (cast(Button)element).text.text);
			} else {
				(cast(Button)element).setState(Button.State.Idle);
			}
		}

		if(!found) {
			(cast(Button)elements[0]).setState(Button.State.Down);
			_value = cast(size_t)elements[0].userData;
			toggleableButton.changeText(label ~ (cast(Button)elements[0]).text.text);
		}
	}

	void buttonPressed(Button b, void *userData) {
		if(_value == cast(int)userData) {
			toggleableButton.setState(Button.State.Idle);
			if(callback !is null)
				callback(this, _value);
			}
		// Checked new enum, uncheck all other and fallback panel
		_value = cast(int)userData;
		foreach(i; 1 .. elements.length) {
			if((cast(Button)elements[i]).userData != userData) {
				(cast(Button)elements[i]).setState(Button.State.Idle);
			} else {
				toggleableButton.changeText(label ~ (cast(Label)elements[i]).text.text);
			}
		}
		toggleableButton.setState(Button.State.Idle);
		if(callback !is null)
			callback(this, _value);
	}

	void buttonReleased(Button b, void *userData) {
		if(_value == cast(int)userData) {
			// Can't uncheck enum, stop unchecking and fallback panel
			b.setState(Button.State.Down);
		}
	}

	void value(size_t val) {

	}

	size_t value() {
		return value;
	}
}

// Group : List of gui elements which are linked to each other, has its own width and height
class Group : GuiElement {
	GuiElement[] elements;
	vec2i bot, top;

	this() {
		super(vec2i(0, 0), vec2i(0, 0), Value_Type.ABSOLUTE, Value_Type.ABSOLUTE);
	}

	private void addElement(int x, int y, int width, int height) {
		if(elements.length == 1) {
			bot = vec2i(x, y);
			top = vec2i(x + width, y + height);
			Position.absolute = bot;
			Size.absolute = vec2i(width, height);
			updateMatrix();
			return;
		}

		if(x < bot.x) bot.x = x;
		if(x + width > top.x) top.x = x + width;
		if(y < bot.y) bot.y = y;
		if(y + height > top.y) top.y = y + height;
		Position.absolute = bot;
		Size.absolute = top - bot;
		updateMatrix();
		updateAnchor();
	}

	void horizontalCenter() {
		int delta = (mainWindow.width / 2 - Size.absolute.x / 2) - Position.absolute.x;

		foreach(element; elements) {
			element.moveBy(vec2i(delta, 0));
		}
		Position.absolute.x = bot.x = mainWindow.width / 2 - Size.absolute.x / 2;
		top.x = bot.x + Size.absolute.x;
		updateMatrix();
		updateAnchor();
	}

	Button addButton(int x, int y, int width, int height, string str, Label.Layout textPosition = Label.Layout.Center) {
		elements ~= new Button(x, y, width, height, str, textPosition);

		addElement(x, y, width, height);

		return cast(Button)elements[$ - 1];
	}

	Button addImageButton(int x, int y, int width, int height, string image, Label.Layout imagePosition = Label.Layout.Center) {
		elements ~= new Button(x, y, width, height, Texture.load(image), imagePosition);

		addElement(x, y, width, height);

		return cast(Button)elements[$ - 1];
	}

	Button addImageButton(int x, int y, int width, int height, Texture texture, Label.Layout imagePosition = Label.Layout.Center) {
		elements ~= new Button(x, y, width, height, texture, imagePosition);

		addElement(x, y, width, height);

		return cast(Button)elements[$ - 1];
	}

	Button addImageButton(int x, int y, int width, int height, Texture[3] textures, Label.Layout imagePosition = Label.Layout.Center) {
		elements ~= new Button(x, y, width, height, textures, imagePosition);

		addElement(x, y, width, height);

		return cast(Button)elements[$ - 1];
	}

	Textbox addTextbox(int x, int y, int width, int height, string str, string defaultString, Label.Layout textPosition = Label.Layout.Center) {
		elements ~= new Textbox(x, y, width, height, str, defaultString, textPosition);

		addElement(x, y, width, height);

		return cast(Textbox)elements[$ - 1];
	}

	Label addLabel(int x, int y, int width, int height, string str, Label.Layout textPosition = Label.Layout.Center) {
		elements ~= new Label(x, y, width, height, str, textPosition);

		addElement(x, y, width, height);

		return cast(Label)elements[$ - 1];
	}

	GuiElement add(GuiElement element) {
		elements ~= element;
		
		addElement(element.Position.absolute.x, element.Position.absolute.y, element.Size.absolute.x, element.Size.absolute.y);

		return element;
	}

	override void render() {
		if(!visible) return;

		foreach(element; elements) {
			element.render();
		}
	}

	override bool cursorEvent(double x, double y) {
		if(!visible) return false;

		bool used = false;
		foreach(element; elements) {
			if(element.cursorEvent(x, y)) used = true;
		}
		return used;
	}

	override bool mouseEvent(double x, double y, int button, int action) {
		if(!visible) return false;

		bool used = false;
		foreach(element; elements) {
			if(element.mouseEvent(x, y, button, action)) used = true;
		}
		return used;
	}

	override bool keyEvent(int key, int action, int mods) {
		if(!visible) return false;

		foreach(element; elements) {
			if(element.keyEvent(key, action, mods)) return true;
		}
		return false;
	}

	override bool characterEvent(uint character) {
		if(!visible) return false;

		foreach(element; elements) {
			if(element.characterEvent(character)) return true;
		}
		return false;
	}

	override void resize(vec2i previous, vec2i current) {
		vec2i pastPosition = Position.absolute;
		super.resize(previous, current);
		vec2i delta = Position.absolute - pastPosition;

		foreach(element; elements) {
			element.resize(previous, current);
			element.moveBy(delta);
		}
	}
}

class Gui {
	GuiElement[] elements;

	this(GuiElement[] elements...) {
		this.elements.length = elements.length;
		foreach(i; 0..elements.length) {
			this.elements[i] = elements[i];
		}
	}

	GuiElement add(GuiElement element) {
		elements ~= element;
		return element;
	}

	Button addButton(int x, int y, int width, int height, string str, Label.Layout textPosition = Label.Layout.Center) {
		elements ~= new Button(x, y, width, height, str, textPosition);
		return cast(Button)elements[$ - 1];
	}

	Textbox addTextbox(int x, int y, int width, int height, string str, string defaultString, Label.Layout textPosition = Label.Layout.Center) {
		elements ~= new Textbox(x, y, width, height, str, defaultString, textPosition);
		return cast(Textbox)elements[$ - 1];
	}

	Label addLabel(int x, int y, int width, int height, string str, Label.Layout textPosition = Label.Layout.Center) {
		elements ~= new Label(x, y, width, height, str, textPosition);
		return cast(Label)elements[$ - 1];
	}

	DropDownMenu addDropDownMenu(int x, int y, int width, int height, string str) {
		elements ~= new DropDownMenu(x, y, width, height, str);
		return cast(DropDownMenu)elements[$ - 1];
	}

	Group addGroup() {
		elements ~= new Group();
		return cast(Group)elements[$ - 1];
	}

	void render() {
		glEnable(GL_BLEND);

		foreach(element; elements) {
			element.render();
		}
		glDisable(GL_BLEND);
	}

	bool cursorEvent(double x, double y) {
		bool used = false;
		foreach(element; elements) {
			if(element.cursorEvent(x, y)) used = true;
		}
		return used;
	}

	bool mouseEvent(double x, double y, int button, int action) {
		bool used = false;
		foreach(element; elements) {
			if(element.mouseEvent(x, y, button, action)) used = true;
		}
		return used;
	}

	bool keyEvent(int key, int action, int mods) {
		foreach(element; elements) {
			if(element.keyEvent(key, action, mods)) return true;
		}
		return false;
	}

	bool characterEvent(uint character) {
		foreach(element; elements) {
			if(element.characterEvent(character)) return true;
		}
		return false;
	}

	void resizeEvent(vec2i previous, vec2i current) {
		foreach(element; elements) {
			element.resize(previous, current);
		}
	}
}