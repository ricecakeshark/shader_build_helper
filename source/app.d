import std.exception;
import std.stdio;
import std.process;
import std.string;
import std.format;

import std.file;
import std.typecons;
import std.path : baseName, isValidPath;

void main()
{
	int result;
	string[] file_name_list = ["texture.frag"];

	//auto target_dir = Directory("./shader/src/glsl/");
	//auto target_file_list = target_dir.entries;

	//riteln(target_dir.entries);

	foreach (entry; "./shader/src/glsl/".dirEntries(SpanMode.shallow))
	{
		build_glsl(entry);
	}
	return;
}

void build_glsl(string file_path)
{
	enforce(file_path.isValidPath);
	enforce(file_path.exists);
	enforce(file_path.isFile);
	string output_path = "./shader/build/spirv/" ~ baseName(file_path).chomp(".glsl") ~ ".spv";
	if (output_path.exists)
	{
		writefln("skipped: %s ", file_path);
		return;
	}
	else
	{
		writefln("building: %s ", file_path);
	}

	Tuple!(int, "status", string, "output") glslang;
	glslang = format(
		"glslangValidator --target-env vulkan1.1 -o %s %s",
		output_path,
		file_path,
	).executeShell();
	glslang.output.writeln();
	return;
}
