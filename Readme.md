# nimcc: A mini C compiler written in Nim

## Prerequisites
- 64-bit Linux environment
    - MacOS is quite compatible with Linux at the source level of assembly, but not fully compatible.

- Having [nim](https://nim-lang.org/), gcc, make, binutils and libc6-dev installed.

    ```
    $ sudo apt install -y nim gcc make binutils libc6-dev
    ```
- Setting up a Linux development environment using Docker
    ```
    Open the directory containing the Dockerfile and type

    $ docker build -t {containerName} .
    $ docker run --rm -it -v $HOME/nimcc:/home/user/nimcc {containerName}
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