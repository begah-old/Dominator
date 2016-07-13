module isolated.file;

import std.stdio;

import isolated.utils.logger;

private {
	File[string] files;

	string Asset_Path = "C:/Users/Mathieu Roux/Documents/D Workspace/isolated/assets/";
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
