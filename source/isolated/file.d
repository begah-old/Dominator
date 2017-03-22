module isolated.file;

public import std.stdio : File;

import std.stdio;

import isolated.utils.logger;
import std.file : thisExePath;
import std.string : lastIndexOf;

private {
	string Asset_Path = "";
}

static this() {
	Asset_Path = thisExePath();
	Asset_Path = Asset_Path[0 .. lastIndexOf(Asset_Path, '\\') + 1];
	if(Asset_Path[lastIndexOf(Asset_Path[0 .. $ - 1], '\\') .. $] == "\\bin\\") {
		Asset_Path = Asset_Path[0 .. lastIndexOf(Asset_Path[0 .. $ - 1], '\\') + 1];
	}

	Asset_Path ~= "assets/";
}

@safe nothrow:

File internal(const(char[]) filename, string mode = "rb") {
	try {
		Logger.info(Asset_Path ~ filename);
		return File(Asset_Path ~ filename, mode);
	} catch(Exception ex) {Logger.error(ex.msg); return File.init;}
}