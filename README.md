# zatsu-cwl-generator
[![release](https://badgen.net/github/release/tom-tan/zatsu-cwl-generator/stable)](https://github.com/tom-tan/zatsu-cwl-generator/releases/latest)
[![container](https://badgen.net/badge/-/docker?icon=docker&label)](https://hub.docker.com/r/ttanjo/zatsu-cwl-generator)
[![Actions Status](https://github.com/tom-tan/zatsu-cwl-generator/workflows/Actions/badge.svg)](https://github.com/tom-tan/zatsu-cwl-generator/actions)

This is a simple CWL document generator from given execution commands.

# Build Requirements
- [Visual Studio Code](https://code.visualstudio.com) (optional)
  - This repository provides a development environment for [Visual Studio Code Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
- [D compiler](https://dlang.org/download.html)
  - I confirmed with `dmd` and `ldc2` but it should work with other compilers such as `gdc`.

# How to execute

There are several ways to execute it. See `zatsu-cwl-generator --help` for more details.

- Use [Docker container](https://hub.docker.com/r/ttanjo/zatsu-cwl-generator)

  ```console
  $ docker run --rm ttanjo/zatsu-cwl-generator:latest "cat aaa.txt bbb.txt > output.txt"
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
  ```

- Download the latest binary from the [release page](https://github.com/tom-tan/zatsu-cwl-generator/releases/latest)
   ```console
   $ export ver=v1.0.5
   $ export os=linux # `export os=osx` for macOS
   $ wget -O zatsu-cwl-generator.tar.xz https://github.com/tom-tan/zatsu-cwl-generator/releases/download/${ver}/zatsu-cwl-generator-${ver}-${os}-x86_64.tar.xz
   $ tar xf zatsu-cwl-generator.tar.xz
   $ chmod +x zatsu-cwl-generator
   $ ./zatsu-cwl-generator "cat aaa.txt bbb.txt > output.txt"
   ...
   ```

- Use `rdmd`
  ```console
  $ ./zatsu-cwl-generator.d "cat aaa.txt bbb.txt > output.txt"
  ...
  ```

- Build a binary and use it
  ```console
  $ ldc2 zatsu-cwl-generator.d
  $ ./zatsu-cwl-generator "cat aaa.txt bbb.txt > output.txt"
  ...
  ```

If you need a static linked binary, add `-static` to the build command:
```console
$ ldc2 zatsu-cwl-generator.d # for dynamic link (default)
$ ldd zatsu-cwl-generator
        /lib/ld-musl-x86_64.so.1 (0x7f476696e000)
        libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7f4766711000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f476696e000)

$ ldc2 -static zatsu-cwl-generator.d # for static link
$ ldd zatsu-cwl-generator
/lib/ld-musl-x86_64.so.1: zatsu-cwl-generator: Not a valid dynamic program
```

# How to test this program

```console
$ rdmd -main -unittest zatsu-cwl-generator.d
```

# How to generate an internal document

```console
$ ldc2 -Dddocs zatsu-cwl-generator.d
```

You can see a HTML file in the `docs` directory.
