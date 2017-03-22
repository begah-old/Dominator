module isolated.utils.timer;

import core.time;

struct Timer {
	private MonoTime time;

	/* Time elapsed (in milliseconds) since timer creation or since last call to reset */
	@property double elapsedTime() {
		Duration timeElapsed = MonoTime.currTime - time;

		return timeElapsed.total!"nsecs" / 1000000.0;
	}

	@property Timer reset() {
		time = MonoTime.currTime;
		return this;
	}
}
