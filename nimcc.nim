
#[
  ? トークナイズ　->　パース　(-> ノードに型付け -> オフセット計算)　-> アセンブリ
]#

import header
import typer
import parse
import codegen
import tokenize

proc main() =

  #? トークナイズ
  token = tokenize()

  #? パース
  var prog: Function = program()

  #? ノードに型付け
  addType(prog)

  #? オフセット計算
  var fn: Function = prog
  while fn != nil:

    var offset = 0
    var vl: LvarList = fn.locals      #! 引数,ローカル変数のためのオフセットを計算
    while vl != nil:                  #! ローカル変数ループ
      offset += 8
      vl.lvar.offset = offset
      vl = vl.next

    fn.stackSize = offset
    fn = fn.next

  #? アセンブリ生成
  codegen(prog)
  quit(0)

#? --------------------------------------------------------------------------------------
# entry point
main()
