import std.exception;
import std.stdio;
import std.process;
import std.string;
import std.format;

import std.file;
import std.typecons;
import std.path : baseName, isValidPath;
import std.parallelism;

void main()
{
	auto build_task_pool = new TaskPool();
	foreach (entry; "./shader/src/glsl/".dirEntries(SpanMode.shallow))
	{
		//build_glsl(entry);
		build_task_pool.put(task!build_glsl(entry));
	}
	build_task_pool.finish(true);
	return;
}

void build_glsl(string input_file_path)
{
	enforce(input_file_path.isValidPath);
	enforce(input_file_path.exists);
	enforce(input_file_path.isFile);
	string output_path = "./shader/build/spirv/" ~ baseName(input_file_path).chomp(".glsl") ~ ".spv";
	if (timeLastModified(input_file_path) < timeLastModified(output_path))
	{
		writefln("skipped: %s ", input_file_path);
		return;
	}
	else
	{
		writefln("building: %s ", input_file_path);
	}

	Tuple!(int, "status", string, "output") glslang;
	glslang = execute([
		"glslangValidator",
		"-V",
		"--target-env", "vulkan1.1",
		"-o", output_path,
		input_file_path,
	]);
	writefln("finished: %s",output_path);
	writeln(glslang.output);
	return;
}
