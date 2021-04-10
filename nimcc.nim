import os
import system
import strformat

if os.paramCount() >= 1:
  echo ".intel_syntax noprefix"
  echo ".global _main"
  echo "_main:"
  echo strformat.fmt"  mov rax, {$os.commandLineParams()[0]}"
  echo "  ret"
  system.quit(0)