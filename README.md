# zatsu-cwl-generator
Zatsu CWL generator

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
  - id: out
    type: stdout
stdout: output.txt
```

# How to test this program

```console
$ rdmd -main -unittest zatsu_cwl_generator.d
```
