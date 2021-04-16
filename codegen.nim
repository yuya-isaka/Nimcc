
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
  echo "  push rdi"

#--------------------------------------------------------

# コードジェネレート
proc gen(node: Node) =

  case node.kind
  of NdNum:
    echo fmt"  push {node.val}"
    return
  of NdExpr:
    gen(node.lhs)
    echo "  add rsp, 8"
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
  of NdReturn:
    gen(node.lhs)
    echo "  pop rax"    # !これまでは毎回ポップしていたが，returnの時だけポップするので良い(複数のノードを生成しない)
    echo "  jmp .Lreturn"
    return
  else:
    discard

  gen(node.lhs)
  gen(node.rhs)

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
  echo ".global main"
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
