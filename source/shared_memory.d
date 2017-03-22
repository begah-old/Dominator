module shared_memory;

import isolated.screen;
import isolated.window;
import isolated.utils.timer;
import isolated.math;
import isolated.gui.font;

__gshared Window mainWindow;
__gshared Screen currentScreen = null;
__gshared Screen lastScreen = null;

__gshared Timer mainTimer;

__gshared Font defaultFont;