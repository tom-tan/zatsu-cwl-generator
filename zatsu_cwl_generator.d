#!/usr/bin/env rdmd
import std;

@safe:

private immutable IntRegex= ctRegex!r"^\d+$";
private immutable DoubleRegex = ctRegex!r"^\d+\.\d+$";

version(unittest) {}
else
void main(string[] args)
{
    if (args.length != 2)
    {
        writefln("Usage: %s <commandline>", args[0]);
        return;
    }
    args[1].toCWL.write;
}

/**
 * Returns: a CWL definition from a given commandline `cmd`.
 */
string toCWL(string cmd)
{
    immutable original_cmd = cmd;
    auto sout = "";
    auto serr = "";

    // detect redirect to stderr
    if (auto arr = cmd.findSplit("2>"))
    {
        immutable pre = arr[0].stripRight;
        assert(arr[1] == "2>");
        immutable post = arr[2].stripLeft;

        auto tmp = post.split;
        enforce(!tmp.empty, "No file specified to be redirected stderr!");
        if (tmp.length == 1)
        {
            serr = tmp[0];
            cmd = pre;
        }
        else
        {
            serr = tmp[1];
            cmd = pre ~ " " ~ tmp[2..$].join(" ");
        }
    }

    // detect redirect to stdout
    if (auto arr = cmd.findSplit(">"))
    {
        immutable pre = arr[0].stripRight;
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
#!/usr/bin/env cwl-runner
# Generated from: %s
class: %s
cwlVersion: %s
baseCommand: %s
EOS", original_cmd, class_, cwlVersion, baseCommand);

    string[] arguments, inputs;
    string[] outputs = [
        q"EOS
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"
EOS"
        ];
    string prevOption;
    foreach(i, a; args[1..$])
    {
        if (a.startsWith("-") && a != "-")
        {
            arguments ~= format("  - %s", a);
            prevOption = a;
        }
        else
        {
            immutable seemsOut = a.seemsOutput(prevOption);

            // guess type from option name
            immutable type = a.guessType(prevOption);
            immutable param = (prevOption.empty ? a : prevOption).toInputParam;
            immutable inParam = seemsOut ? param~"_name" : param;
            immutable outParam = seemsOut ? param : "";
            arguments ~= format("  - $(inputs.%s)", inParam);
            inputs ~= format(q"EOS
  - id: %s
    type: %s%s
EOS", inParam, seemsOut ? "string" : type, a == "-" ? "\n    streamable: true" : "");
            if (seemsOut)
            {
                outputs ~= format(q"EOS
#  - id: %s
#    type: %s
#    outputBinding:
#      glob: "$(inputs.%s)"
EOS", outParam, type, inParam);
            }
            prevOption = "";
        }
    }
    cwl ~= "arguments:" ~ (arguments.empty ? " []" : "\n"~arguments.join("\n")) ~ "\n";
    cwl ~= "inputs:" ~ (inputs.empty ? " []\n" : "\n"~inputs.join);

    if (!stdout_.empty)
    {
        outputs ~= q"EOS
  - id: out
    type: stdout
EOS";
    }
    if (!stderr_.empty)
    {
        outputs ~= q"EOS
  - id: err
    type: stderr
EOS";
    }
    cwl ~= "outputs:" ~ (outputs.empty ? " []\n" : "\n"~outputs.join);

    if (!stdout_.empty)
    {
        cwl ~= format("stdout: %s\n", stdout_);
    }
    if (!stderr_.empty)
    {
        cwl ~= format("stderr: %s\n", stderr_);
    }
    return cwl;
}

/// Simple example
unittest
{
    assert("cat aaa.txt bbb.txt > output.txt".toCWL ==
        q"EOS
#!/usr/bin/env cwl-runner
# Generated from: cat aaa.txt bbb.txt > output.txt
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
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"
  - id: out
    type: stdout
stdout: output.txt
EOS");
}

/// with options
unittest
{
    assert("head -n 5 ccc.txt > output.txt".toCWL ==
        q"EOS
#!/usr/bin/env cwl-runner
# Generated from: head -n 5 ccc.txt > output.txt
class: CommandLineTool
cwlVersion: v1.0
baseCommand: head
arguments:
  - -n
  - $(inputs.n)
  - $(inputs.ccc_txt)
inputs:
  - id: n
    type: int
  - id: ccc_txt
    type: File
outputs:
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"
  - id: out
    type: stdout
stdout: output.txt
EOS");
}

/// guess output object
unittest
{
    assert("gcc -o sample.exe sample.c".toCWL ==
           q"EOS
#!/usr/bin/env cwl-runner
# Generated from: gcc -o sample.exe sample.c
class: CommandLineTool
cwlVersion: v1.0
baseCommand: gcc
arguments:
  - -o
  - $(inputs.o_name)
  - $(inputs.sample_c)
inputs:
  - id: o_name
    type: string
  - id: sample_c
    type: File
outputs:
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"
#  - id: o
#    type: File
#    outputBinding:
#      glob: "$(inputs.o_name)"
EOS");
}

/// use standard input
unittest
{
    assert("samtools view -bS -".toCWL ==
        q"EOS
#!/usr/bin/env cwl-runner
# Generated from: samtools view -bS -
class: CommandLineTool
cwlVersion: v1.0
baseCommand: samtools
arguments:
  - $(inputs.view)
  - -bS
  - $(inputs.bS)
inputs:
  - id: view
    type: Any
  - id: bS
    type: File
    streamable: true
outputs:
  - id: all-for-debugging
    type:
      type: array
      items: [File, Directory]
    outputBinding:
      glob: "*"
EOS");
}

/**
 * Returns: a valid CWL input parameter id generated from `value`
 */
string toInputParam(string value)
in(!value.empty)
do
{
    if (value == "-")
    {
        return "stdin";
    }

    if (value.startsWith("-"))
    {
        value = value.stripLeft("-");
    }

    if (value.matchFirst(IntRegex))
    {
        return "_" ~ value;
    }
    else if (value.matchFirst(DoubleRegex))
    {
        return "_" ~ value.tr(".", "_");
    }
    else
    {
        return value.baseName.tr(".-", "_");
    }
}

///
unittest
{
    assert("5".toInputParam == "_5");
    assert("3.14".toInputParam == "_3_14");
    assert("foobar.txt".toInputParam == "foobar_txt");
    assert("value".toInputParam == "value");

    // For #5
    assert("this-file-is.txt".toInputParam == "this_file_is_txt");

    assert("-n".toInputParam == "n");
    assert("--option".toInputParam == "option");

    assert("../relative/path/to/file.txt".toInputParam == "file_txt");
    assert("/abspath/to/dir".toInputParam == "dir");

    assert("-".toInputParam == "stdin");
}

/**
 * Returns: a type string reasoned from the option and its value
 */
string guessType(string value, string option = "")
{
    // guess from `option`
    if (option.endsWith("dir"))
    {
        return "Directory";
    }
    else if (option.endsWith("file"))
    {
        return "File";
    }

    // guess from `value`
    if (value.match(IntRegex))
    {
        return "int";
    }
    else if (value.match(DoubleRegex))
    {
        return "double";
    }
    else if (value.canFind(dirSeparator))
    {
        // It will be an absolute path or a relative path
        return value.baseName.canFind(".") ? "File" : "Directory";
    }
    else if (value.canFind("."))
    {
        // It will be a file in current directory
        return "File";
    }
    else if (value.endsWith("dir"))
    {
        return "Directory";
    }
    else if (value == "-")
    {
        return "File";
    }
    return "Any";
}

///
unittest
{
    /* guess a type from the option if it is provided */
    // if option ends with `dir`, it will be a directory
    assert("foo".guessType("--outdir") == "Directory");
    // if option ends with `file`, it will be a File
    assert("bar".guessType("--outfile") == "File");

    /* otherwise guess a type from its value */
    // if the value seems to be an integer, it will be an integer
    assert("13".guessType == "int");
    // if the value seems to be a floating point, it will be a double precision number
    assert("13.5".guessType == "double");
    // if the value seems to be a file with an extension, it will be a File
    assert("foobar.txt".guessType == "File");
    assert("../hoge.txt".guessType == "File");
    // if the value is `"-"`, it will be a File
    assert("-".guessType == "File");
    // if it seems to be a path but no extensions, it will be a directory
    assert("/path/to/dir".guessType == "Directory");
    // if the value seems to be a directory name (i.e. ends with `dir`), it will be a directory
    assert("seems_dir".guessType == "Directory");

    // return `Any` if it cannot guess a type
    assert("13a".guessType == "Any");
    assert("unknown-value".guessType("--unknown-option") == "Any");
}

/**
 * Returns: true if a given `value` seems to be an output object, false otherwise
 */
bool seemsOutput(string value, string option = "")
{
    // if the value is `"-"`, it should not be an output object
    if (value == "-")
    {
        return false;
    }

    // guess from `option`
    if (option == "-o")
    {
        return true;
    }
    else if (option.startsWith("--out"))
    {
        return true;
    }

    // guess from `value`
    if (value.startsWith("out"))
    {
        return true;
    }
    return false;
}

///
unittest
{
    // if the option starts with `-o`, it seems to be an output object
    assert("aaa.txt".seemsOutput("-o"));
    assert(!"aaa.txt".seemsOutput("-a"));

    // if the option starts with `--output`, it seems to be an output object
    assert("bbb.txt".seemsOutput("--output"));
    assert("bbb.txt".seemsOutput("--outdir"));
    assert(!"bbb.txt".seemsOutput("--auto"));

    // if the value starts with `out`, it seems to be an output object
    assert("output.txt".seemsOutput);
    assert("outdir".seemsOutput);
    assert(!"input.txt".seemsOutput);

    // if the value is `"-"`, it should not be an output object
    assert(!"-".seemsOutput);
    assert(!"-".seemsOutput("-o"));
}
