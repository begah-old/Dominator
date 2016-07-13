module app;

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import std.algorithm;
import std.array;

import isosphere;

import gl3n.linalg;

int main() {

	IsoSphere s = new IsoSphere(5);

	File file = File("C:/Users/Mathieu Roux/Documents/D Workspace/Test/assets/" ~ "out.txt", "w");

	file.write("Position = [ ");
	auto pos = s.vertices.map!(a => a.position).array;
	foreach(i, p; pos) {
		if((i + 1) % 5 == 0) { file.writeln("vec3(", p.x, ", ", p.y, ", ", p.z, "), "); file.write("\t"); }
		else file.write("vec3(", p.x, ", ", p.y, ", ", p.z, "), ");
	}

	file.write(" ];");
	file.close();
	auto norm = s.vertices.map!(a => a.normal);
	auto textcoord = s.vertices.map!(a => a.textcoord);

	return 0;
}
