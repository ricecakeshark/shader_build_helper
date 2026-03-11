import std.exception;
import std.stdio;
import std.process;
import std.string;
import std.format;

import std.file;
import std.typecons : Tuple;
import std.path : baseName, isValidPath, setExtension;
import std.parallelism;
import core.runtime;

void main()
{
	bool verbose;

	foreach (arg; Runtime.args)
	{
		switch (arg)
		{
		case "--verbode":
			verbose = true;
			break;
		default:
			break;
		}
	}

	auto build_task_pool = new TaskPool();
	writefln("starting build... (cpus=%d)", build_task_pool.size);
	foreach (DirEntry entry; dirEntries("shader/src/glsl", "*.glsl", SpanMode.shallow))
	{
		build_task_pool.put(task!build_glsl(entry, verbose));
	}
	build_task_pool.finish(true);
	writeln("finished build.");
	return;
}

void build_glsl(string input_path, bool verbose = false)
{
	string output_path;

	enforce(input_path.isValidPath);
	enforce(input_path.exists);
	enforce(input_path.isFile);
	output_path = "shader/build/spirv/" ~ baseName(input_path).setExtension("spv");
	if (output_path.exists == true)
	{
		if (timeLastModified(input_path) < timeLastModified(output_path))
		{
			writefln("Skip: %s", input_path);
			return;
		}
	}
	writefln("Start: %s", input_path);

	Tuple!(int, "status", string, "output") glslang;
	glslang = execute([
		"glslangValidator",
		"-V",
		"--target-env", "vulkan1.1",
		"-o", output_path,
		input_path,
	]);
	writefln("Finish: %s", output_path);
	if (verbose)
	{
		writeln(glslang.output);
	}

	return;
}
