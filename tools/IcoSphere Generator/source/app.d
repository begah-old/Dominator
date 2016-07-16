module app;

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import std.algorithm;
import std.array;

import icosphere;

import gl3n.linalg;

int main() {
	int subdivisionLevel = 3;
	Start:
	IsoSphere s = new IsoSphere(subdivisionLevel);

<<<<<<< HEAD
	File file = File("C:/Users/Begah/Documents/Dominator/tools/IcoSphere Generator/assets/" ~ "out" ~ to!string(subdivisionLevel) ~ ".txt", "w");
=======
	File file = File("C:/Users/Begah/Documents/Dominator/IcoSphere Generator/assets/" ~ "out" ~ to!string(subdivisionLevel) ~ ".txt", "w");
>>>>>>> origin/master

	auto pos = s.vertices.map!(a => a.position).array;

	file.write("IcoSphere" ~ to!string(subdivisionLevel) ~ "_Positions = [ ");
	foreach(i, p; pos) {
		if(i == pos.length - 1) file.write("vec3(", p.x, ", ", p.y, ", ", p.z, ")");
		else if((i + 1) % 5 == 0) { file.writeln("vec3(", p.x, ", ", p.y, ", ", p.z, "), "); file.write("\t"); }
		else file.write("vec3(", p.x, ", ", p.y, ", ", p.z, "), ");
	}
	file.writeln(" ];");
	file.writeln();

	auto norm = s.vertices.map!(a => a.normal).array;

	file.write("IcoSphere" ~ to!string(subdivisionLevel) ~ "_Normals = [ ");
	foreach(i, n; norm) {
		if(i == norm.length - 1) file.write("vec3(", n.x, ", ", n.y, ", ", n.z, ")");
		else if((i + 1) % 5 == 0) { file.writeln("vec3(", n.x, ", ", n.y, ", ", n.z, "), "); file.write("\t"); }
		else file.write("vec3(", n.x, ", ", n.y, ", ", n.z, "), ");
	}
	file.writeln(" ];");
	file.writeln();

	auto textcoord = s.vertices.map!(a => a.textcoord).array;

	file.write("IcoSphere" ~ to!string(subdivisionLevel) ~ "_TextCoords = [ ");
	foreach(i, t; textcoord) {
		if(i == textcoord.length - 1) file.write("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, ")");
		else if((i + 1) % 5 == 0) { file.writeln("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, "), "); file.write("\t"); }
		else file.write("vec2(", t.x, ", ", t.y, "), ");
	}
	file.writeln(" ];");

	if(subdivisionLevel != 5) {
		subdivisionLevel++;
		goto Start;
	}

<<<<<<< HEAD
	readln();
=======
>>>>>>> origin/master
	return 0;
}
