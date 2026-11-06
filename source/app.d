import std.array;
import std.exception : enforce;
import std.file;

import std.getopt;
import std.typecons : Tuple;
import std.path : asNormalizedPath, baseName, chainPath, isValidPath, setExtension;
import std.parallelism : task, TaskPool;
import std.process : escapeShellCommand, execute;
import std.stdio;

void main(string[] args)
{
	BuildOption build_opt;

	auto opt_info = getopt(
		args,
		"src", &(build_opt.src_path),
		"dest", &build_opt.dest_path,
		"verbose", &build_opt.verbose,
	);

	auto build_task_pool = new TaskPool();
	writefln("starting build... (cpus=%d)", build_task_pool.size);
	foreach (DirEntry entry; dirEntries(build_opt.src_path, "*.glsl", SpanMode.shallow))
	{
		build_task_pool.put(task!build_shader(entry, build_opt));
	}
	build_task_pool.finish(true);
	writeln("finished build.");
	return;
}

void build_shader(string source_file, BuildOption build_opt)
{
	string dest_file;
	enforce(source_file.isValidPath);
	enforce(source_file.exists);
	enforce(source_file.isFile);

	dest_file = chainPath(build_opt.dest_path, baseName(source_file).setExtension("spv"))
		.array;
	if (build_opt.force_to_build == false && dest_file.exists == true)
	{
		if (timeLastModified(source_file) < timeLastModified(dest_file))
		{
			writefln("Skip: %s", source_file);
			return;
		}
	}

	string[] glslang_command;
	glslang_command = [
		"glslang",
		"-V",
		"--target-env", "vulkan1.4",
		"-Os",
		"-o", dest_file,
		source_file,
	];

	writefln("Started build: %s", source_file);

	writefln("execute: '%s'", escapeShellCommand(glslang_command));
	Tuple!(int, "status", string, "output") glslang;
	glslang = execute(glslang_command);
	if (glslang.status == 0)
	{
		writefln("Finished build: %s", dest_file);
		if (build_opt.verbose)
		{
			writeln(glslang.output);
		}
	}
	else
	{
		writefln("Failed build: %s", dest_file);
		writeln(glslang.output);
	}
	return;
}

struct BuildOption
{
	string src_path = "shader/src/glsl";
	string dest_path = "shader/build/spirv";
	bool verbose = false;
	bool force_to_build = false;
}
