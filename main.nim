import header
import parse
import codegen
import tokenize

# メイン関数
proc main() =

  # トークナイズ
  token = tokenize() # グローバル変数tokenにセット

  # パース
  var prog: Program = program()

  # オフセット計算
  var offset = 0
  var lvar: Lvar = prog.locals
  while true:
    if lvar == nil:
      break
    offset += 8
    lvar.offset = offset
    lvar = lvar.next
  prog.stackSize = offset

  # アセンブリ生成
  codegen(prog)

  quit(0)

#---------------------------------------------------------

main()
