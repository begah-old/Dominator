module isolated.utils.logger;

import Abort = core.internal.abort;
import std.stdio;
import std.exception;
import std.conv;

struct Logger
{
	@trusted nothrow:

	static void info(T : string)(T info, string filename = __FILE__, size_t line = __LINE__) {
		try {
			stdout.writefln("INFO (%s|%d) : %s", filename, line, info);
		} catch(ErrnoException ex) {
			abort("Error : " ~ collectExceptionMsg(ex));
		} catch(Exception ex) {
			abort("Error : " ~ collectExceptionMsg(ex));
		}
	}

	static void info(T)(T info, string filename = __FILE__, size_t line = __LINE__) {
		T copy = info;
		try {
			Logger.info!string(to!string(copy), filename, line);
		} catch(Exception ex) {
			abort("Error : " ~ collectExceptionMsg(ex));
		}
	}

	static void warning(string warning, string filename = __FILE__, size_t line = __LINE__) {
		try {
			stdout.writefln("WARNING (%s|%d) : %s", filename, line, warning);
		} catch(ErrnoException ex) {
			abort("Error : " ~ collectExceptionMsg(ex));
		} catch(Exception ex) {
			abort("Error : " ~ collectExceptionMsg(ex));
		}
	}

	static void error(string error, string filename = __FILE__, size_t line = __LINE__) {
		try {
			stderr.writefln("ERROR (%s|%s) : %s", filename, line, error);
		} catch(ErrnoException ex) {
			abort("Fatal Error : " ~ collectExceptionMsg(ex));
		} catch(Exception ex) {
			abort("Fatal Error : " ~ collectExceptionMsg(ex));
		}
	}
}

void abort(T)(T value = "", string filename = __FILE__, size_t line = __LINE__) @trusted nothrow {
	Logger.error(value, filename, line);
	try { readln(); }
	catch(Exception ex) {}
	Abort.abort("");
}