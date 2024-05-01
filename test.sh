#!/bin/bash -u

test() {
  expect="$1"
  input="$2"

  ./src/nimcc "$input" > asm.s || exit
  gcc -static -o asm asm.s
  ./asm
  result="$?"

  if [ "$result" = "$expect" ]; then
    echo "$input => $result"
  else
    echo "$input => $expect expected, but got $result"
    exit 1
  fi
}

test 0 0
test 42 42

echo OK