import os
import strformat

proc error(msg: string) =
  stderr.writeLine("Error: ", msg)

proc main(args: seq[string]) =
  if args.len != 1:
    error(&"invalid number of arguments ... {args.len}")
    quit(1)

  echo "  .globl main"
  echo "main:"
  echo &"  mov ${args[0]}, %rax"
  echo "  ret"

if isMainModule:
  main(commandLineParams())