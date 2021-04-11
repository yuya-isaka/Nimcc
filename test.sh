#!/bin/bash
assert() {
    expected="$1"
    input="$2"

    ./nimcc "$input" > tmp.s
    cc -o tmp tmp.s
    ./tmp
    actual="$?"

    if [ "$actual" = "$expected" ]; then
        echo "$input => $actual"
    else
        echo "$input => $expected expected, but got $actual"
        exit 1
    fi
}

# nim c nimcc.nim

assert 0 0
assert 30 30
assert 21 "5+20-4"
assert 20 "5+5+5+5"

echo OK