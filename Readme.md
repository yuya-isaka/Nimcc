# Nimcc: A mini C compiler written in Nim (WIP)

## Prerequisites
- A Docker environment or a native 64-bit Linux environment on x86_64 architecture.
    - MacOS is quite compatible with Linux at the source level of assembly, but not fully compatible.

## Setup

### Setting up the environment using Docker

- Setting up the Linux development environment using a Dockerfile.
    - The environment will include the following tools installed: [nim](https://nim-lang.org/), gcc, make, binutils, libc6-dev.

- The code below assumes that Nimcc repository is cloned directly under `$HOME` directory.

- Create a Docker container named 'nimcc' from an image. (Feel free to change the name of the container as you like.)

    ```
    Open the directory containing the Dockerfile and type

    $ docker build -t nimcc .
    $ docker run --rm -it -w /home/user/Nimcc -v $HOME/Nimcc:/home/user/Nimcc nimcc
    ```

### Setting up the environment on Linux (x86_64)

- The environment setup on a native Linux system mirrors the Docker environment, ensuring consistency across platforms.

- Install the necessary tools directly on your Linux system

    ```
    $ sudo apt update
    $ sudo apt install -y gcc make git binutils libc6-dev
    ```

## How to test
- Open the directory and type `make` in the terminal.

    ```
    In Docker
    If it says 'OK', it means that all tests have passed!
    ------------------------------------------------------

    $ make
      .
      .
      .
    struct t {int a; int b;} x; struct t y; sizeof(y); => 16
    struct t {int a; int b;}; struct t y; sizeof(y); => 16
    struct t {char a[2];}; { struct t {char a[4];}; } struct t y; sizeof(y); => 2
    struct t {int x;}; int t=1; struct t y; y.x=2; t+y.x; => 3
    OK
    ```

    - Running the make command will execute the test code for the Nimcc compiler.

    - The test code is written in C language and is in the file test.c. (It's worth noting that the test code itself is written in C language.)

    - You can also write your own C code and compile it using Nimcc.

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
