module isolated.utils.timer;

import core.time;

struct Timer {

  nothrow @safe :

  private MonoTime time;

  /* Time elapsed (in milliseconds) since timer creation or since last call to reset */
  @property long elapsedTime() {
    Duration timeElapsed = MonoTime.currTime - time;

    return timeElapsed.total!"msecs";
  }

  void reset() {
    time = MonoTime.currTime;
  }
}
