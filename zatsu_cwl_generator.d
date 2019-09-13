#!/usr/bin/env rdmd
import std;

@safe:

void main(string[] args)
{
    if (args.length != 2) {
        writefln("Usage: %s <commandline>", args[0]);
    }
    args[1].to_cwl.write;
}

auto to_cwl(string cmd)
{
    auto sout = "";
    auto serr = "";

    // detect redirect to stderr
    if (auto arr = cmd.findSplit("2>")) {
        auto pre = arr[0].stripRight;
        assert(arr[1] == "2>");
        auto post = arr[2].stripLeft;

        auto tmp = post.split;
        enforce(!tmp.empty, "No file specified to be redirected stderr!");
        if (tmp.length == 1) {
            serr = tmp[0];
            cmd = pre;
        } else {
            serr = tmp[1];
            cmd = pre ~ " " ~ tmp[2..$].join(" ");
        }
    }

    // detect redirect to stdout
    if (auto arr = cmd.findSplit(">")) {
        auto pre = arr[0].stripRight;
        assert(arr[1] == ">");
        auto post = arr[2].stripLeft;

        enforce(post.split.length == 1, "One file should be allowed after `>`!");
        sout = post;
        cmd = pre;
    }

    immutable class_ = "CommandLineTool";
    immutable cwlVersion = "v1.0";
    immutable stdout_ = sout.empty ? "" : sout;
    immutable stderr_ = serr.empty ? "" : serr;

    auto args = cmd.split;
    enforce(!args.empty);

    immutable baseCommand = args[0];

    auto cwl = format(q"EOS
class: %s
cwlVersion: %s
baseCommand: %s
EOS", class_, cwlVersion, baseCommand);

    string[] arguments, inputs;
    bool opt_arg;
    foreach(i, a; args[1..$]) {
        if (a.startsWith("-")) {
            arguments ~= a;
            opt_arg = true;
        } else {
            // guess type from option name
            immutable type = guess_type(opt_arg ? args[i-1]: "", a);
            immutable param = a.tr(".", "_");
            arguments ~= format("  - $(inputs.%s)", param);
            inputs ~= format(q"EOS
  - id: %s
    type: %s
EOS", param, type);
        }
    }
    cwl ~= "arguments:" ~ (arguments.empty ? " []" : "\n"~arguments.join("\n")) ~ "\n";
    cwl ~= "inputs:" ~ (inputs.empty ? " []\n" : "\n"~inputs.join);

    string[] outputs;
    if (!stdout_.empty) {
        outputs ~= q"EOS
  - id: out
    type: stdout
EOS";
    }
    if (!stderr_.empty) {
        outputs ~= q"EOS
  - id: err
    type: stderr
EOS";
    }
    cwl ~= "outputs:" ~ (outputs.empty ? " []\n" : "\n"~outputs.join);

    if (!stdout_.empty) {
        cwl ~= format("stdout: %s\n", stdout_);
    }
    if (!stderr_.empty) {
        cwl ~= format("stderr: %s\n", stderr_);
    }
    return cwl;
}

auto guess_type(string option, string value)
{
    if (option.endsWith("dir")) {
        return "Directory";
    } else if (option.endsWith("file")) {
        return "File";
    }
    if (value.match(ctRegex!r"^\d+$")) {
        return "int";
    } else if (value.match(ctRegex!r"^\d+\.\d+$")) {
        return "double";
    } else if (value.canFind(".")) {
        return "File";
    }
    return "Any";
}

unittest {
    assert("cat aaa.txt bbb.txt > output.txt".to_cwl,
        q"EOS
class: CommandLineTool
cwlVersion: v1.0
baseCommand: cat
arguments:
  - $(inputs.aaa_txt)
  - $(inputs.bbb_txt)
inputs:
  - id: aaa_txt
    type: File
  - id: bbb_txt
    type: File
outputs:
  - id: out
    type: stdout
stdout: output.txt
EOS");
}
