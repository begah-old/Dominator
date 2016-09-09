module isolated.file;

import std.stdio;

import isolated.utils.logger;
import std.file : thisExePath;
import std.string : lastIndexOf;

private {
	File[string] files;

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
		if((filename in files) is null) {
			files[filename] = File(Asset_Path ~ filename, mode);
		}
		return files[filename];
	} catch(Exception ex) {Logger.error(ex.msg); return File.init;}
}
