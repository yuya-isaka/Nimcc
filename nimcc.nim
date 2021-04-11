
import os
import system
import strformat

proc convertInput(input: seq, index: var int): string =
  result = input[index]
  inc(index)

if os.paramCount() >= 2:
  quit("引数の個数が正しくありません．")

var i = 0
let input = os.commandLineParams()

echo ".intel_syntax noprefix"
echo ".global _main"
echo "_main:"
echo strformat.fmt"  mov rax, {convertInput(input, i)}"

while len(input) >= i:
  if input[i] == "+":
    inc(i)
    echo strformat.fmt"  add rax, {convertInput(input, i)}"
    continue

  if input[i] == "-":
    inc(i)
    echo strformat.fmt"  sub rax, {convertInput(input, i)}"
    continue

  system.quit(strformat.fmt"予期しない文字です．:{input[i]}")

echo "  ret"
system.quit(0)