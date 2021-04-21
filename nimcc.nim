
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
  while fn != nil:   #! Functionループ

    var offset = 0
    var vl: LvarList = fn.locals  #! 引数＋ローカル変数のためのオフセットを計算
    while vl != nil:   #! ローカル変数ループ
      offset += 8
      vl.lvar.offset = offset
      vl = vl.next

    fn.stackSize = offset
    fn = fn.next

  # *アセンブリ生成
  codegen(prog)
  quit(0)

#---------------------------------------------------------

main()
