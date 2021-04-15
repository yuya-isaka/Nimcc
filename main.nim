import header
import parse
import codegen
import tokenize

# メイン関数
proc main() =
  token = tokenize() # グローバル変数にセット
  var prog = program() # 副作用でグローバル変数codeにノードをストア

  var offset = 0
  var lvar = prog.locals
  while true:
    if lvar == nil:
      break
    offset += 8
    lvar.offset = offset
    lvar = lvar.next
  prog.stackSize = offset

  codegen(prog)

  quit(0)


main()