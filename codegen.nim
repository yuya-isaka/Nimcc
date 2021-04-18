
#[
  * 目的：ノード連結リストと変数連結リストから「アセンブリ」を出力
]#

import header
import strformat

#-----------------------------------------------------

# 変数生成
proc genAddr(node: Node) =
  if node.kind == NdLvar:
    echo fmt"  lea rax, [rbp-{node.arg.offset}]"
    echo "  push rax"

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
  echo "  push rdi"     # !NdAssignはNdExprStmtにラップされてるから，ここでpushしたものは，add rsp, 8で抜き取られる(ちゃんと取り除ける)

#--------------------------------------------------------

var labelSeq: int # !0で初期化してくれる
var funcname: string
var argreg = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]

#-----------------------------------------------------

# コードジェネレート
proc gen(node: Node) =

  case node.kind
  of NdNum:
    echo fmt"  push {node.val}"
    return
  of NdExprStmt:    # !意味のない式，数値対策？ 3;みたいな
    gen(node.lhs)
    echo "  add rsp, 8"   # !pop raxをする代わり？ スタックポインタを上に8あげればpopしたのと同じ.
    return
  of NdLvar:
    genAddr(node)
    load()
    return
  of NdAssign:
    genAddr(node.lhs)
    gen(node.rhs)
    store()
    return
  of NdIf:
    var seq = labelSeq  # !ラベル番号はユニークにする
    inc(labelSeq)
    if node.els != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lelse{seq}"
      gen(node.then)
      echo fmt"  jmp .Lend{seq}"
      echo fmt".Lelse{seq}:"  #TODO :を付け忘れた覚書
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
  of NdWhile:
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
    return    # TODO return忘れてた覚書
  of NdFor:
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
  of NdBlock:
    for tmp in node.body:
      gen(tmp)
      # echo "  pop rax" # 多分readExprStmtのおかげでいらなくなった（便利です）
    return
  of NdFuncall:
    var nargs = 0
    var arg = node.args
    while arg != nil:
      gen(arg)
      inc(nargs)
      arg = arg.next

    var i = nargs - 1
    while i >= 0:
      echo fmt"  pop {argreg[i]}"
      dec(i)

    var seq = labelSeq
    inc(labelSeq)
    echo "  mov rax, rsp"
    echo "  and rax, 15"
    echo fmt"  jnz .Lcall{seq}"
    echo "  mov rax, 0"
    echo fmt"  call {node.funcname}"
    echo fmt"  jmp .Lend{seq}"
    echo fmt".Lcall{seq}:"
    echo "  sub rsp, 8"
    echo "  mov rax, 0"
    echo fmt"  call {node.funcname}"
    echo "  add rsp, 8"
    echo fmt".Lend{seq}:"
    echo "  push rax"
    return
  of NdReturn:
    gen(node.lhs)
    echo "  pop rax"    # !これまでは毎回ポップしていたが，returnの時だけポップするので良い(複数のノードを生成しない)
    echo fmt"  jmp .Lreturn.{funcname}"
    return
  else:
    discard

  gen(node.lhs)   # !これより下のNode型は，2つの値を使用する計算だから，まとめて上でgen(node.lhs),gen(node.rhs)している
  gen(node.rhs)   # !case文の各Node型の中で実行しても良い

  echo "  pop rdi"
  echo "  pop rax"

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

  echo "  push rax"   # !式全体の結果を，スタックトップにプッシュ

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

    echo "  push rbp"
    echo "  mov rbp, rsp"
    echo fmt"  sub rsp, {fn.stackSize}"

    # プログラムに入ってるノードが尽きるまでアセンブリ生成(連結リストだからこの書き方ができる)
    var node = fn.node
    while true:
      if node == nil:
        break
      gen(node)
      node = node.next

    # 終わり
    echo fmt".Lreturn.{funcname}:"
    echo "  mov rsp, rbp"
    echo "  pop rbp"
    echo "  ret"

    fn = fn.next
