
#[
  * トークナイズ　→　パース　→　アセンブリ
]#

import header
import parse
import codegen
import tokenize

# メイン関数
proc main() =

  # *トークナイズ
  token = tokenize() # グローバル変数tokenにセット

  # *パース
  var prog: Function = program()
  # オフセット計算
  var fn: Function = prog
  while true:   # !Functionループ
    if fn == nil:
      break

    var offset = 0
    var lvar: Lvar = prog.locals
    while true:   # !ローカル変数ループ
      if lvar == nil:
        break
      offset += 8
      lvar.offset = offset
      lvar = lvar.next

    fn.stackSize = offset
    fn = fn.next

  # *アセンブリ生成
  codegen(prog)
  quit(0)

#---------------------------------------------------------

main()
