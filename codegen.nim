
#[
  * 目的：ノード連結リストと変数連結リストから「アセンブリ」を出力
]#

import header
import strformat

#-----------------------------------------------------

proc gen(node: Node)

# 変数生成
proc genAddr(node: Node) =
  case node.kind:
  of NdLvar:
    echo fmt"  lea rax, [rbp-{node.arg.offset}]"  #! アドレス計算を行うが，メモリアクセスは行わず，アドレス計算の結果そのものをraxに代入
    #! raxにはアドレスが入ってる
    echo "  push rax"
    return
  of NdDeref:
    gen(node.lhs)
    return
  else:
    errorAt("not an lvalue", node.tok)  #! Token型を渡す設計にすることで， コードジェネレートの際のエラー位置を正確に確認できるようになった（本当か

# 関数フレーム，プロローグ
proc load() =
  echo "  pop rax"
  echo "  mov rax, [rax]"
  echo "  push rax"

# 関数フレーム，エピローグ
proc store() =
  echo "  pop rdi"
  echo "  pop rax"
  echo "  mov [rax], rdi"
  echo "  push rdi"     #! NdAssignはNdExprStmtにラップされてるから，ここでpushしたものは，add rsp, 8で抜き取られる(ちゃんと取り除ける)

#--------------------------------------------------------

var labelSeq: int #! 0で初期化してくれる
var funcname: string
#! 引数は6つ
var argreg = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"] #! 関数の引数の順番． x86-64, ABI仕様で決められている．　このルールに従わないと適切な機械語を生成できない

#-----------------------------------------------------

# コードジェネレート
proc gen(node: Node) =

  #! ここはreturnされるcase switch文
  case node.kind
  of NdNum: #todo 数値の時はこのNodeKind
    echo fmt"  push {node.val}"
    return  #! 計算しないNodeKindは全てリターン
  of NdExprStmt:  #todo 左辺を生成するだけの時はこのNodeKind
    gen(node.lhs)
    echo "  add rsp, 8"   #! pop raxをする代わり？ スタックポインタを上に8あげればpopしたのと同じ.
    return
  of NdLvar:  #todo 変数を使用する時はこのNodeKind
    genAddr(node)
    load()
    return
  of NdAssign:  #todo 変数を定義する時はこのNodeKind
    genAddr(node.lhs)
    gen(node.rhs)
    store()
    return
  of NdAddr:
    genAddr(node.lhs)
    return
  of NdDeref:
    gen(node.lhs)
    load()
    return
  of NdIf:  #todo if文はこのNodeKind
    var seq = labelSeq  #! ラベル番号はユニークにする
    inc(labelSeq)
    if node.els != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lelse{seq}"
      gen(node.then)
      echo fmt"  jmp .Lend{seq}"
      echo fmt".Lelse{seq}:"  #! :を付け忘れた覚書
      gen(node.els)
      echo fmt".Lend{seq}:"
    else:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lend{seq}"
      gen(node.then)
      echo fmt".Lend{seq}:"
    return
  of NdWhile: #todo while文はこのNodeKind
    var seq = labelSeq
    inc(labelSeq)
    echo fmt".Lbegin{seq}:"
    gen(node.cond)
    echo "  pop rax"
    echo "  cmp rax, 0"
    echo fmt"   je .Lend{seq}"
    gen(node.then)
    echo fmt"   jmp .Lbegin{seq}"
    echo fmt".Lend{seq}:"
    return    #! return忘れてた覚書
  of NdFor: #todo for文はこのNodeKind
    var seq = labelSeq
    inc(labelSeq)
    if node.init != nil:
      gen(node.init)
    echo fmt".Lbegin{seq}:"
    if node.cond != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"   je .Lend{seq}"
    gen(node.then)
    if node.inc != nil:
      gen(node.inc)
    echo fmt"   jmp .Lbegin{seq}"
    echo fmt".Lend{seq}:"
    return
  of NdBlock: #todo {}の中身はひたすら生成, body: seq[Node]
    for tmp in node.body:
      gen(tmp)
      # echo "  pop rax" # 多分readExprStmtのおかげでいらなくなった（便利です）
    return
  of NdFuncall: #todo 関数の時はこのNodeKind

    #* 関数の引数をローカル変数として格納
    var nargs = 0
    var arg = node.args
    while arg != nil:
      gen(arg)  #! 順番にスタックにpushされている．
      inc(nargs)
      arg = arg.next

    var i = nargs - 1
    while i >= 0:
      echo fmt"  pop {argreg[i]}" #! 順番にスタックからpopされている．(ABI仕様), rspが関数の開始位置まで戻る
      dec(i)

    var seq = labelSeq
    inc(labelSeq)
    echo "  mov rax, rsp" #! raxは16の倍数じゃないとダメ！
    echo "  and rax, 15"  #! 関数を呼ぶ前にRSPを調整するようにして、RSPを16の倍数になるように調整(pushやpopはRSPを8バイト単位で変更するから、call命令を発行するときに必ずしもRSPが16の倍数になっているとは限らん)
    echo fmt"  jnz .Lcall{seq}" #! 比較結果が0じゃなかったら飛ぶ
    echo "  mov rax, 0" 
    echo fmt"  call {node.funcname}"
    echo fmt"  jmp .Lend{seq}"
    echo fmt".Lcall{seq}:"
    echo "  sub rsp, 8" #! jnz .Lcall{seq}が発動されるとここに飛んできて，スタックを伸ばす
    echo "  mov rax, 0" 
    echo fmt"  call {node.funcname}"
    echo "  add rsp, 8" #! 関数読んだ後にスタックを縮ませる
    echo fmt".Lend{seq}:"
    echo "  push rax"
    return
  of NdReturn:  #todo returnの時は左辺を生成してpopreturn
    gen(node.lhs)
    echo "  pop rax"    #! これまでは毎回ポップしていたが，returnの時だけポップするので良い(複数のノードを生成しない)
    echo fmt"  jmp .Lreturn.{funcname}"
    return
  else:
    discard #! ここで捨てないと下の処理見れない

  gen(node.lhs)   #! これより下のNode型は，2つの値を使用する計算だから，まとめて上でgen(node.lhs),gen(node.rhs)している
  gen(node.rhs)   #! case文の各Node型の中で実行しても良い

  echo "  pop rdi"
  echo "  pop rax"

  #todo 計算&比較ふぇーーーーーーーーーず(returnせず，スタックに値を保存するだけ)
  case node.kind
  of NdAdd:
    echo "  add rax, rdi"
  of NdSub:
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

  echo "  push rax"   #! 式全体の結果を，スタックトップにプッシュ

#--------------------------------------------------------------------------

# 完成形アセンブリ出力関数
proc codegen*(prog: Function) =
  # 始まり
  echo ".intel_syntax noprefix"

  var fn = prog
  while fn != nil:
    echo fmt".global {fn.name}" # macだと_mainで動く
    echo fmt"{fn.name}:"
    funcname = fn.name

    #* プロローグ
    echo "  push rbp"
    echo "  mov rbp, rsp"
    echo fmt"  sub rsp, {fn.stackSize}"

    var i = 0
    #! vlの中身は,0-6の連結
    var vl = fn.params  #! ここでオフセットを指定するためにparamsは使われる．ここには引数だけ入ってる
    while vl != nil:
      var lvar = vl.lvar
      #!  レジスタの値をそのローカル変数のためのスタック上の領域に書き出し(ローカル変数と同じように扱える)
      echo fmt"  mov [rbp-{lvar.offset}], {argreg[i]}" #! 最初に6つのローカル変数のぶんのスタック領域を確保しておく（空白で良い）
      inc(i)
      vl = vl.next

    # プログラムに入ってるノードが尽きるまでアセンブリ生成(連結リストだからこの書き方ができる)
    var node = fn.node
    while node != nil:
      gen(node)
      node = node.next

    # *エピローグ
    echo fmt".Lreturn.{funcname}:"
    echo "  mov rsp, rbp"
    echo "  pop rbp"
    echo "  ret"

    fn = fn.next
