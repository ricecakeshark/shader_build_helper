import std.exception : enforce;
import std.file;
//import std.getopt;
import std.typecons : Tuple;
import std.path : baseName, isValidPath, setExtension;
import std.parallelism : task, TaskPool;
import std.process : execute;
import std.stdio;

void main()
{
	BuildFlag build_flag;
	build_flag.get();

	auto build_task_pool = new TaskPool();
	writefln("starting build... (cpus=%d)", build_task_pool.size);
	foreach (DirEntry entry; dirEntries("shader/src/glsl", "*.glsl", SpanMode.shallow))
	{
		build_task_pool.put(task!build_glsl(entry, build_flag));
	}
	build_task_pool.finish(true);
	writeln("finished build.");
	return;
}

void build_glsl(string input_path, BuildFlag build_flag)
{
	string output_path;

	enforce(input_path.isValidPath);
	enforce(input_path.exists);
	enforce(input_path.isFile);
	output_path = "shader/build/spirv/" ~ baseName(input_path).setExtension("spv");
	if (build_flag.force_to_build == false && output_path.exists == true)
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
		"--target-env", "vulkan1.4",
		(build_flag.optimize_aggresive)?"-Os":"",
		"-o", output_path,
		input_path,
	]);
	if (glslang.status == 0)
	{
		writefln("Finish : %s", output_path);
		if (build_flag.verbose)
		{
			writeln(glslang.output);
		}
	}
	else
	{
		writefln("Fail : %s", output_path);
		writeln(glslang.output);
	}

	return;
}

struct BuildFlag
{
	import core.runtime;

	bool verbose;
	bool force_to_build;
	bool optimize_aggresive;

	void get()
	{
		foreach (arg; Runtime.args)
		{
			switch (arg)
			{
			case "--verbose", "-v":
				this.verbose = true;
				break;
			case "--force", "-f":
				this.force_to_build = true;
				break;
			case "--optimize", "-O":
				this.optimize_aggresive = true;
				break;
			default:
				break;
			}
		}
		return;
	}
}
