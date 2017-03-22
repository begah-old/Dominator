module isolated.gui.builder;

import shared_memory;

import isolated.screen;
import isolated.window;
import isolated.math;
import isolated.utils.logger;

import isolated.gui;
import isolated.graphics.texture;

class GuiBuilder : Screen {

	FontManager fontManager;
	Gui gui;
	DropDownMenu ddMenu;
	Gui builderElements;
	DropDownMenu builderElementsDescriptor;

	this() {
		mainWindow.addCallBack(&cursorEvent);
		mainWindow.addCallBack(&mouseEvent);
		mainWindow.addCallBack(&characterEvent);
		mainWindow.addCallBack(&keyEvent);
		mainWindow.addCallBack(&resizeEvent);
	}

	void initUpdate(double d) {
		
	}

	void initRender(double d) {
		fontManager = new FontManager("arial");

		gui = new Gui();
		Group group = gui.addGroup();
		group.anchor(GuiElement.Anchor.Up | GuiElement.Anchor.Right);

		group.addTextbox(mainWindow.width / 2 - 50, mainWindow.height - 20, 200, 20, "Name : ", "gui", Label.Layout.Center).characterLimit(5);
		group.addButton(mainWindow.width / 2 + 155, mainWindow.height - 20, 75, 20, "Confirm");
		group.add(new Button(mainWindow.width / 2 + 235, mainWindow.height - 20, 20, 20, Texture.load!3("Gui_Builder/Save_Icon.png")));
		ddMenu = cast(DropDownMenu)gui.add(new DropDownMenu(0, mainWindow.height, 150, 20, "Add"));
		ddMenu.anchor(GuiElement.Anchor.Up);
		ddMenu.addButton("Label", 150, 20).pressed = &buttonCallback;
		ddMenu.addButton("Button", 150, 20).pressed = &buttonCallback;
		ddMenu.addButton("Textbox", 150, 20).pressed = &buttonCallback;
		builderElementsDescriptor = gui.addDropDownMenu(mainWindow.width - 150, mainWindow.height, 150, 20, "Gui Elements :");
		builderElementsDescriptor.anchor(GuiElement.Anchor.Right | GuiElement.Anchor.Up);
		
		group.horizontalCenter();

		EnumButton eButton = new EnumButton(0, 300, 200, 20, "Tests : ");
		eButton.addEnum("One", 1);
		eButton.addEnum("Two", 3);
		eButton.addEnum("Morgane", 69);
		gui.add(eButton);

		builderElements = new Gui();
	}

	void buttonCallback(Button b, void* userData) {
		void addTextBox(DropDownMenu ddm, string str, string defaultValue, int width, int height) {
			Textbox textBox = ddm.addTextbox(str, defaultValue, width, height);
			textBox.userData = cast(void*)ddm; textBox.released = &textboxCallback;
		}

		if(b == ddMenu.elements[1]) {
			Label label = builderElements.addLabel(0, 0, 100, 20, "Label");
			DropDownMenu ddMenu2 = builderElementsDescriptor.addDropDownMenu("Label", 150, 20);
			ddMenu2.userData = cast(void*)label;
			addTextBox(ddMenu2, "X : ", "0", 150, 20);
			addTextBox(ddMenu2, "Y : ", "0", 150, 20);
			addTextBox(ddMenu2, "Label : ", "Label", 150, 20);
		} else if(b == ddMenu.elements[2]) {
			Button button = builderElements.addButton(0, 0, 100, 20, "Button");
			DropDownMenu ddMenu2 = builderElementsDescriptor.addDropDownMenu("Button ", 150, 20);
			ddMenu2.userData = cast(void*)button;
			addTextBox(ddMenu2, "X : ", "0", 150, 20);
			addTextBox(ddMenu2, "Y : ", "0", 150, 20);
			addTextBox(ddMenu2, "Label : ", "Label", 150, 20);
		} else if(b == ddMenu.elements[3]) {
			Textbox textbox = builderElements.addTextbox(0, 0, 100, 20, "Textbox", "None");
			DropDownMenu ddMenu2 = builderElementsDescriptor.addDropDownMenu("Textbox ", 150, 20);
			ddMenu2.userData = cast(void*)textbox;
			addTextBox(ddMenu2, "X : ", "0", 150, 20);
			addTextBox(ddMenu2, "Y : ", "0", 150, 20);
			addTextBox(ddMenu2, "Label : ", "Label", 150, 20);
			addTextBox(ddMenu2, "Default : ", "None", 150, 20);
		}
	}

	void textboxCallback(Button b, void *userData) {
		Textbox t = cast(Textbox)b;
		DropDownMenu ddm = cast(DropDownMenu)userData;

		GuiElement element = cast(GuiElement)ddm.userData;
		switch(t.label) {
			case "X : ":
				try {
					int x = to!int(t.value);
					element.moveBy(vec2i(x - GuiElement.valueAbsolute(element.Position, element.Position_Type).x, 0));
				} catch(Exception ex) {
					t.currentText="";
				}
				break;
			case "Y : ":
				try {
					int y = to!int(t.value);
					element.moveBy(vec2i(0, y - GuiElement.valueAbsolute(element.Position, element.Position_Type).y));
				} catch(Exception ex) {
					t.currentText="";
				}
				break;
			case "Label : ":
				if(Textbox textbox = cast(Textbox)element) {
					textbox.setText(t.value);
				} else {
					Label label = cast(Label)ddm.userData;
					label.changeText(t.value);
				}
				break;
			case "Default : ":
				Textbox textbox = cast(Textbox)element;
				textbox.setText(null, t.value);
				break;
			default: break;
		}
	}

	void cursorEvent(double x, double y) {
		gui.cursorEvent(x, y);
		builderElements.cursorEvent(x, y);
	}

	void mouseEvent(double x, double y, int button, int action) {
		gui.mouseEvent(x, y, button, action);
		builderElements.mouseEvent(x, y, button, action);
	}

	void characterEvent(uint character) {
		gui.characterEvent(character);
		builderElements.characterEvent(character);
	}

	void keyEvent(int key, int action, int mods) {
		gui.keyEvent(key, action, mods);
		builderElements.keyEvent(key, action, mods);
	}

	void resizeEvent(vec2i previous, vec2i current) {
		gui.resizeEvent(previous, current);
		builderElements.resizeEvent(previous, current);
	}

	void update(double delta) {

	}

	void render(double delta) {
		gui.render();
		builderElements.render();
	}

	void destroyUpdate(double d) {

	}

	void destroyRender(double d) {

	}
}