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

nim c nimcc.nim

assert 0 0
assert 30 30
assert 21 "5+20-4"
assert 20 "5+5+5+5"
assert 41 " 12 + 34 - 5"
assert 30 " 10 + 30 - 10   "
assert 46 "4+6*7"
assert 12 "4*(9-6)"
assert 4 "(3+5)/2"
assert 10 "  (  2 +18)/   2"
assert 7 " -10+17"
assert 0 "-4 + -2 + -3 + 3 + 6"
assert 10 " - - +10"
assert 0 "0==1"
assert 1 "40 == 40"
assert 1 "0!=1"
assert 0 "30!=30"
assert 1 "0<1"
assert 0 "1 < 1"
assert 0 "2<1"
assert 1 "0<=1"
assert 1 "1 <= 1"
assert 0 "3  <= 2"
assert 1 "1>0"
assert 0 "2 > 2"
assert 0 "1>2"
assert 1 "1>=0"
assert 1 "3>=3"
assert 0 "0>=1"

echo OK