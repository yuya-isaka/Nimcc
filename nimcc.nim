
#[
  ? トークナイズ　->　パース　(-> ノードに型付け -> オフセット計算)　-> アセンブリ
  ? 関数を引数と返り値から読むと理解が深まる
  ? 全て型付けしてる方がわかりやすいかな？？
]#

import header
import typer
import parse
import codegen
import tokenize

# 無理矢理オフセット（スタックサイズ）を8の倍数にする.  (今までは全部8バイトだったが，Char型が1バイトになったため，全体のstacksizeが8の倍数じゃない可能性がある)
proc alignTo(n: int, align: int): int =
  return (n + align - 1) and not (align - 1)

proc main() =

  #? トークナイズ
  token = tokenize()

  #? パース(識別子はここで型付け)
  var prog: Program = program()

  #? ノードに型付け
  addType(prog)

  #? オフセット計算
  var fn: Function = prog.fns
  while fn != nil:                      # 関数ループ
    var offset = 0
    var vl: LvarList = fn.locals        # 引数,ローカル変数のためのオフセットを計算
    while vl != nil:                    # ローカル変数ループ
      offset += sizeType(vl.lvar.ty)    # 対象識別子(変数)の型で，確保するサイズを決める(intとptrは「8」, arrayは「type*size」)
      vl.lvar.offset = offset
      vl = vl.next
    fn.stackSize = alignTo(offset, 8)
    fn = fn.next

  #? アセンブリ生成
  codegen(prog)
  quit(0)

main()