# zatsu-cwl-generator
[![Actions Status](https://github.com/tom-tan/zatsu-cwl-generator/workflows/Actions/badge.svg)](https://github.com/tom-tan/zatsu-cwl-generator/actions)

This is a simple CWL definition generator from given execution commands.

# Build Requirements
- [Visual Studio Code](https://code.visualstudio.com) (optional)
  - This repository provides a development environment for [Visual Studio Code Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- [D compiler](https://dlang.org/download.html)
  - I confirmed with `dmd` and `ldc2` but it should work with other compilers such as `gdc`.

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
$ ldc2 zatsu_cwl_generator.d
$ ./zatsu_cwl_generator "cat aaa.txt bbb.txt > output.txt"
...
```

If you need a static linked binary, add `-mtriple=x86_64-alpine-linux-musl -static` to the build command:
```console
$ ldc2 zatsu_cwl_generator.d # for dynamic link (default)
$ ldd zatsu_cwl_generator
        linux-vdso.so.1 (0x00007ffde1327000)
        librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f83cf2d4000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f83cf0d0000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f83ceeb1000)
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f83ceb13000)
        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f83ce8fb000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f83ce50a000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f83cf718000)

$ ldc2 -mtriple=x86_64-alpine-linux-musl -static zatsu_cwl_generator.d # for static link
$ ldd zatu_cwl_generator
        not a dynamic executable
```

# How to test this program

```console
$ rdmd -main -unittest zatsu_cwl_generator.d
```

# How to generate an internal document

```console
$ ldc2 -Dddocs zatsu_cwl_generator.d
```

You can see a HTML file in the `docs` directory.
