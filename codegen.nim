
#[
  ? 目的：ノード連結リストと変数連結リストから「アセンブリ」を出力
]#

import header
import typer
import strformat

#? ---------------------------------------------------------------------------------------------------------
var labelSeq: int                                         #! 0で初期化してくれる
var funcname: string
                                                          #! 引数は6つ
var argreg = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]     #! 関数の引数の順番． x86-64, ABI仕様で決められている．　このルールに従わないと適切な機械語を生成できない

#? ---------------------------------------------------------------------------------------------------------
proc gen(node: Node)

#? 左辺値生成
proc genAddr(node: Node) =                                #! 左辺値生成（アドレス返すってこと）, C言語の左辺値は基本的にメモリのアドレスを指定する式
  case node.kind:
  of NdLvar:
    var lvar = node.lvar

    if lvar.isLocal:
      echo fmt"  lea rax, [rbp-{lvar.offset}]"             #! アドレス計算を行うが，メモリアクセスは行わず，アドレス計算の結果そのもの(アドレス）をraxに代入
      echo "  push rax"                                   #! raxにはアドレスが入ってる!!!重要だよ！！（評価結果じゃないんだよ！）
    else:
      echo fmt"  push offset {lvar.name}"
    return
  of NdDeref:
    gen(node.lhs)                                         #! *p = 3 のようにデリファレンス経由で値を代入するときに対応するため， pのアドレスが生成されるように左辺値をコンパイル
    return
  else:
    errorAt("not an lvalue", node.tok)                    #! Token型を渡す設計にすることで， コードジェネレートの際のエラー位置を正確に確認できるようになった（本当か

proc genLval(node: Node) =
  if node.ty.kind == TyArray:                             #! 配列へのアクセスはデリファレンス経由じゃないとだめってこと？？
    errorAt("not an lvalue", node.tok)
  genAddr(node)

#? 変数取り出し
proc load() =                                            
  echo "  pop rax"
  echo "  mov rax, [rax]"
  echo "  push rax"

#? 変数格納
proc store() =                                            
  echo "  pop rdi"
  echo "  pop rax"
  echo "  mov [rax], rdi"
  echo "  push rdi"                                       #! NdAssignはNdExprStmtにラップされてるから，ここでpushしたものは，add rsp, 8で抜き取られる(ちゃんと取り除ける)

#? ---------------------------------------------------------------------------------------------------------
proc gen(node: Node) =

  case node.kind                                          #! ここはreturnされるcase switch文
  of NdNull:
    return
  of NdNum:
    echo fmt"  push {node.val}"
    return                                                #! 計算しないNodeKindは全てリターン
  of NdExprStmt:
    gen(node.lhs)
    echo "  add rsp, 8"                                   #! pop raxをする代わり？ スタックポインタを上に8あげればpopしたのと同じ.
    return
  of NdLvar:                                              #? 変数利用
    genAddr(node)                                         #! 変数を右辺値として扱う場合は， まず左辺値として評価
    if node.ty.kind != TyArray:
      load()                                              #! スタックトップにある結果をアドレスとみなして，そのアドレスから値をロード
    return
  of NdAssign:                                            #? 代入
    genLval(node.lhs)                                     #! 左辺値からアドレス生成(配列はエラー, デリファレンス経由じゃないとだめ？)
    gen(node.rhs)                                         #! 右辺値としてコンパイルして結果を生成
    store()                                               #! スタックトップに値があるから，それを左辺値のアドレスに代入
    return
  of NdAddr:                                              #? アドレス生成
    genAddr(node.lhs)                                     #! 左辺値としてコンパイル！！！！！！！ -> アドレスを計算してスタックに格納
    return
  of NdDeref:                                             #? デリファレンス
    gen(node.lhs)                                         #! 右辺値としてコンパイル. ->　何らかのアドレスを計算するコードに変換されるはず(そうでなければその結果をデリファレンスすることはできない．その場合はエラーにする） -> 最終的にgenAddrをどこかで呼び出すということ
    if node.ty.kind != TyArray:
      load()                                              #! 何らかのアドレスを計算した後， スタックに評価結果を残す， それをロード
    return
  of NdIf:
    var label = labelSeq                                  #! ラベル番号はユニークにする
    inc(labelSeq)
    if node.els != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lelse{label}"
      gen(node.then)
      echo fmt"  jmp .Lend{label}"
      echo fmt".Lelse{label}:"                            #! :を付け忘れた覚書
      gen(node.els)
      echo fmt".Lend{label}:"
    else:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lend{label}"
      gen(node.then)
      echo fmt".Lend{label}:"
    return
  of NdWhile:
    var label = labelSeq
    inc(labelSeq)
    echo fmt".Lbegin{label}:"
    gen(node.cond)
    echo "  pop rax"
    echo "  cmp rax, 0"
    echo fmt"   je .Lend{label}"
    gen(node.then)                                        #! node.thenはExprStmt()にラップされてるから，スタックトップに値は残らない
    echo fmt"   jmp .Lbegin{label}"
    echo fmt".Lend{label}:"
    return                                                #! return忘れてた覚書
  of NdFor:
    var label = labelSeq
    inc(labelSeq)
    if node.init != nil:
      gen(node.init)
    echo fmt".Lbegin{label}:"
    if node.cond != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"   je .Lend{label}"
    gen(node.then)
    if node.inc != nil:
      gen(node.inc)
    echo fmt"   jmp .Lbegin{label}"
    echo fmt".Lend{label}:"
    return
  of NdBlock:                                             # {}の中身はひたすら生成, body: seq[Node]
    for tmp in node.body:
      gen(tmp)                                            #! genで評価された結果がスタックに積まれるが，　ExprStmt()にラップされてるから，スタックトップに値は残らない
                                                          # -> echo "  pop rax" # readExprStmtのおかげでいらなくなった（便利です）
    return
  of NdFuncall:
    #* 関数の引数をローカル変数として格納
    var nargs = 0
    var arg = node.args                                   #! parseのprimary()内で作られたnode.argsの値を順番に評価し，アセンブリ生成する
    while arg != nil:
      gen(arg)                                            #! 順番にスタックにPUSH
      inc(nargs)
      arg = arg.next

    var i = nargs - 1
    while i >= 0:
      echo fmt"  pop {argreg[i]}"                         #! 順番にスタックからPOP(ABI仕様), ついでにRSPが関数の開始位置(RBP)まで戻る
      dec(i)                                              # これで空白のRBP以下が埋められた

    var label = labelSeq
    inc(labelSeq)
    echo "  mov rax, rsp"                                 #! 関数呼び出しの前にRSPは16の倍数じゃないとダメ！
    echo "  and rax, 15"                                  #! 関数を呼ぶ前にRSPを16の倍数になるように調整(PUSHやPOPはRSPを8バイト単位で変更するから、call命令を発行するときに必ずしもRSPが16の倍数になっているとは限らん)
                                                          #! and 15, 15 -> 15   and 16, 15 -> 0   and 17, 15 -> 1
    echo fmt"  jnz .Lcall{label}"                         #! 比較結果!=0で飛ぶ(RAXが16の倍数じゃない場合飛ぶ)
    echo "  mov rax, 0" 
    echo fmt"  call {node.funcname}"
    echo fmt"  jmp .Lend{label}"
    echo fmt".Lcall{label}:"                              #! jnz .Lcallで飛んでくる
    echo "  sub rsp, 8"                                   #! スタックを伸ばす(RSPが16の倍数になるように調整)
    echo "  mov rax, 0"                                   #! RAX初期化 
    echo fmt"  call {node.funcname}"
    echo "  add rsp, 8"                                   #! スタックを縮ませ元に戻す
    echo fmt".Lend{label}:"
    echo "  push rax"                                     #! 評価結果を格納
    return
  of NdReturn:
    gen(node.lhs)
    echo "  pop rax"                                      #! 関数全体の評価結果がスタックトップ(RSP)に入っている．　取り出してRAXにセット．
    echo fmt"  jmp .Lreturn.{funcname}"
    return
  else:
    discard                                               #! ここで捨てないと下の処理見れない

  gen(node.lhs)                                           #! これより下のNode型は，2つの値を使用する計算だから，まとめて上でgen(node.lhs),gen(node.rhs)している
  gen(node.rhs)

  echo "  pop rdi"
  echo "  pop rax"

  case node.kind                                          #? 計算&比較ふぇーーーーーーーーーず(returnせず，スタックに値を保存するだけ)
  of NdAdd:
    if node.ty.base != nil:
      echo fmt"  imul rdi, {sizeType(node.ty.base)}"                                #! rdi = rdi * {}  
    echo "  add rax, rdi"
  of NdSub:
    if node.ty.base != nil:
      echo fmt"  imul rdi, {sizeType(node.ty.base)}"
    echo "  sub rax, rdi"
  of NdMul:
    echo "  imul rax, rdi"
  of NdDiv:
    echo "  cqo"
    echo "  idiv rdi"
  of NdEq:
    echo "  cmp rax, rdi"
    echo "  sete al"
    echo "  movzb rax, al"
  of NdNe:
    echo "  cmp rax, rdi"
    echo "  setne al"
    echo "  movzb rax, al"
  of NdL:
    echo "  cmp rax, rdi"
    echo "  setl al"
    echo "  movzb rax, al"
  of NdLe:
    echo "  cmp rax, rdi"
    echo "  setle al"
    echo "  movzb rax, al"
  else:
    discard

  echo "  push rax"                                       #! 式全体の結果を，スタックトップにプッシュ

#? ---------------------------------------------------------------------------------------------------------
proc emitData(prog: Program) =                           # 完成形アセンブリ出力関数
  echo ".data"

  var vl = prog.globals
  while vl != nil:
    var lvar = vl.lvar
    echo fmt"{lvar.name}:"
    echo fmt"  .zero {sizeType(lvar.ty)}"
    vl = vl.next

proc emitText(prog: Program) =
  echo ".text"

  var fn = prog.fns
  while fn != nil:
    echo fmt".global {fn.name}"                           # macだと_mainで動く
    echo fmt"{fn.name}:"
    funcname = fn.name

    #? プロローグ
    echo "  push rbp"
    echo "  mov rbp, rsp"
    echo fmt"  sub rsp, {fn.stackSize}"

    var i = 0
                                                          #! vlの中身は,0-6の連結
    var vl = fn.params                                    #! ここでオフセットを指定するためにparamsは使われる．ここには引数だけ入ってる
    while vl != nil:
      var lvar = vl.lvar
                                                          #!  レジスタの値をそのローカル変数のためのスタック上の領域に書き出し(ローカル変数と同じように扱える)
      echo fmt"  mov [rbp-{lvar.offset}], {argreg[i]}"    #! 最初に6つのローカル変数のぶんのスタック領域を確保しておく（空白で良い）
      inc(i)
      vl = vl.next

    var node = fn.node                                    # 関数が持つノードが尽きるまでアセンブリ生成(連結リストだからこの書き方)
    while node != nil:
      gen(node)
      node = node.next

    #? エピローグ
    echo fmt".Lreturn.{funcname}:"
    echo "  mov rsp, rbp"                                 #! RSP(スタックトップ)をRBPの位置に移動
    echo "  pop rbp"                                      #! POPするとRSP兼RBPの値(上にあるRBPのアドレス)をスタックから取り出して， RBPにストア -> RBPが元に戻る(上のRBPに戻る) -> RSPがリターンアドレスを指す
    echo "  ret"                                          #! スタックからアドレスを一つポップ(リターンアドレスのはず），　そのアドレスにジャンプ

    fn = fn.next

proc codegen*(prog: Program) =
  echo ".intel_syntax noprefix"
  emitData(prog)
  emitText(prog)