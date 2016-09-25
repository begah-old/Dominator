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

	File combinedFile = File("C:/Users/Mathieu Roux/Documents/D Workspace/Dominator/tools/IcoSphere Generator/assets/icosphere_data.d", "w");
	combinedFile.writeln("module isolated.math.icosphere_data;\n");
	combinedFile.writeln("import isolated.math : vec3, vec2, vec2i;\n");
	combinedFile.writeln("package :\n");

	Start:
	IsoSphere s = new IsoSphere(subdivisionLevel);

	File file = File("C:/Users/Mathieu Roux/Documents/D Workspace/Dominator/tools/IcoSphere Generator/assets/" ~ "out" ~ to!string(subdivisionLevel) ~ ".txt", "w");

	void fileWrite(T...)(T data) {
		file.write(data);
		combinedFile.write(data);
	}void fileWriteln(T...)(T data) {
		file.writeln(data);
		combinedFile.writeln(data);
	}

	auto levelIndices = s.levelIndices;
	fileWrite("static immutable int[] IcoSphere" ~ to!string(subdivisionLevel) ~ "_LevelIndeces = [ ");
	foreach(i, indece; levelIndices) {
		if(i == levelIndices.length - 1)
			fileWrite(indece, " ");
		else
			fileWrite(indece, ", ");
	}
	fileWriteln("];\n");

	auto pos = s.vertices.map!(a => a.position).array;

	fileWrite("static immutable vec3[] IcoSphere" ~ to!string(subdivisionLevel) ~ "_Positions = [ ");
	foreach(i, p; pos) {
		if(i == pos.length - 1) fileWrite("vec3(", p.x, ", ", p.y, ", ", p.z, ")");
		else if((i + 1) % 5 == 0) { fileWriteln("vec3(", p.x, ", ", p.y, ", ", p.z, "), "); fileWrite("\t"); }
		else fileWrite("vec3(", p.x, ", ", p.y, ", ", p.z, "), ");
	}
	fileWriteln(" ];\n");

	auto norm = s.vertices.map!(a => a.normal).array;

	fileWrite("static immutable vec3[] IcoSphere" ~ to!string(subdivisionLevel) ~ "_Normals = [ ");
	foreach(i, n; norm) {
		if(i == norm.length - 1) fileWrite("vec3(", n.x, ", ", n.y, ", ", n.z, ")");
		else if((i + 1) % 5 == 0) { fileWriteln("vec3(", n.x, ", ", n.y, ", ", n.z, "), "); fileWrite("\t"); }
		else fileWrite("vec3(", n.x, ", ", n.y, ", ", n.z, "), ");
	}
	fileWriteln(" ];\n");

	auto textcoord = s.vertices.map!(a => a.textcoord).array;

	fileWrite("static immutable vec2[] IcoSphere" ~ to!string(subdivisionLevel) ~ "_TextCoords = [ ");
	foreach(i, t; textcoord) {
		if(i == textcoord.length - 1) fileWrite("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, ")");
		else if((i + 1) % 5 == 0) { fileWriteln("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, "), "); fileWrite("\t"); }
		else fileWrite("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, "), ");
	}
	fileWriteln(" ];\n");

	auto textcoord_offset = s.vertices.map!(a => a.textcoordOffset).array;

	fileWrite("static immutable vec2[] IcoSphere" ~ to!string(subdivisionLevel) ~ "_TextCoords_Offset = [");
	foreach(i, t; textcoord_offset) {
		if(i == textcoord_offset.length - 1) fileWrite("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, ")");
		else if((i + 1) % 5 == 0) { fileWriteln("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, "), "); fileWrite("\t"); }
		else fileWrite("vec2(", t.x, ", ", t.y / 2.0f + 0.5f, "), ");
	}
	fileWriteln(" ];\n");

	if(subdivisionLevel != 5) {
		subdivisionLevel++;
		goto Start;
	}

	readln();
	return 0;
}
