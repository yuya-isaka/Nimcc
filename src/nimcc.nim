import os
import strformat

proc main(args: seq[string]) =
  if args.len != 1:
    stderr.writeLine(&"Error: invalid number of arguments {args.len}")
    quit(1)

  echo "  .globl main"
  echo "main:"
  echo &"  mov ${args[0]}, %rax"
  echo "  ret"

if isMainModule:
  main(commandLineParams())