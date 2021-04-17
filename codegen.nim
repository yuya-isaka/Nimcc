
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
  echo "  push rdi"     # !NdAssignはNdExprにラップされてるから，ここでpushしたものは，add rsp, 8で抜き取られる(ちゃんと取り除ける)

#--------------------------------------------------------

var labelseq: int # !0で初期化してくれる

#-----------------------------------------------------

# コードジェネレート
proc gen(node: Node) =

  case node.kind
  of NdNum:
    echo fmt"  push {node.val}"
    return
  of NdExpr:    # !意味のない式，数値対策？ 3;みたいな
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
    var seq = labelseq  # !ラベル番号はユニークにする
    inc(labelseq)
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
  of NdReturn:
    gen(node.lhs)
    echo "  pop rax"    # !これまでは毎回ポップしていたが，returnの時だけポップするので良い(複数のノードを生成しない)
    echo "  jmp .Lreturn"
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
proc codegen*(prog: Program) =
  # 始まり
  echo ".intel_syntax noprefix"
  echo ".global main" # macだと_mainで動く
  echo "main:"

  echo "  push rbp"
  echo "  mov rbp, rsp"
  echo fmt"  sub rsp, {prog.stackSize}"

  # プログラムに入ってるノードが尽きるまでアセンブリ生成(連結リストだからこの書き方ができる)
  var node = prog.node
  while true:
    if node == nil:
      break
    gen(node)
    node = node.next

  # 終わり
  echo ".Lreturn:"
  echo "  mov rsp, rbp"
  echo "  pop rbp"
  echo "  ret"
