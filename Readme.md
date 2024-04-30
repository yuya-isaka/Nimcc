# Nimcc: A mini C compiler written in Nim (WIP)

## Prerequisites
- 64-bit Linux environment
    - MacOS is quite compatible with Linux at the source level of assembly, but not fully compatible.

## Setup
- Setting up the Linux development environment using a Dockerfile.
    - The environment will include the following tools installed: "[nim](https://nim-lang.org/), gcc, make, binutils, libc6-dev".

- The code below assumes that Nimcc repository is cloned directly under HOME directory.

    ```
    Open the directory containing the Dockerfile and type

    $ docker build -t {container-name} .
    $ docker run --rm -it -v -w /home/user/Nimcc $HOME/Nimcc:/home/user/Nimcc {container-name}
    ```

## How to run
- Open the directory and type ```make``` in the terminal.

## Features
- A nimcc can execute the code written in test.c.
    - Basic arithmetic operations
    - Unary plus and unary minus
    - Comparison operations
    - Functions
    - Local variables
    - Control syntax (if, while, for)
    - Compound statement (Block)
    - Pointer
    - Primitive data eype (int)

## Reference
- https://www.sigbus.info/compilerbook

<!-- ## License
MIT -->
<!-- Copyright 2021 Yuya Isaka under the terms of the MIT license
found at http://www.opensource.org/licenses/mit-license.html -->
