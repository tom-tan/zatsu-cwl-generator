import std.stdio;
import std.algorithm;
import std.range;

void main()
{
    writefln("class: CommandLineTool\ncwlVersion: v1.0\nbaseCommand: cat\n");
    writefln("arguments: []\n");
    writefln("inputs: []\n");
    writefln("outputs:\n  - id: out\n    type: stdout\nstdout: output.txt\n");
}
