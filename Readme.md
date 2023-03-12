# Nimcc: A mini C compiler written in Nim

## Prerequisites
- 64-bit Linux environment
    - MacOS is quite compatible with Linux at the source level of assembly, but not fully compatible.

- Having [nim](https://nim-lang.org/), gcc, make, binutils and libc6-dev installed.

## Setup
- Setting up a Linux development environment using Docker

- The code below assumes that nim-cghd repository is cloned directly under HOME directory.

    ```
    Open the directory containing the Dockerfile and type

    $ docker build -t {container-name} .
    $ docker run --rm -it -v -w /home/user/nim-cghd $HOME/nim-cghd:/home/user/nim-cghd {container-name}
    ```

## How to run
- Open the directory and type ```make``` in the terminal.

## Features
- A nimcc can execute the code written in test.c.
<!-- - Basic arithmetic operations
- Unary plus and unary minus
- Comparison operations
- Functions
- Local variables
- Control syntax (if, while, for)
- Compound statement (Block)
- Pointer
- Primitive data eype (int) -->

## Reference
- https://www.sigbus.info/compilerbook

<!-- ## License
MIT -->
<!-- Copyright 2021 Yuya Isaka under the terms of the MIT license
found at http://www.opensource.org/licenses/mit-license.html -->
