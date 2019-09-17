# zatsu-cwl-generator
This is a simple CWL definition generator from a given execution commands.

# How to execute

```console
$ ./zatsu_cwl_generator.d "cat aaa.txt bbb.txt > output.txt"
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
```

or:

```console
$ dmd zatsu_cwl_generator.d -of=zatsu_cwl_generator
$ ./zatsu_cwl_generator "cat aaa.txt bbb.txt > output.txt"
...
```

# How to test this program

```console
$ rdmd -main -unittest zatsu_cwl_generator.d
```

# How to generate an internal document

```console
dmd -Dddocs zatsu_cwl_generator.d
```

You can see a HTML file in the `docs` directory.
