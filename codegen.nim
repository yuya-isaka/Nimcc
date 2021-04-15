import header
import strformat

#--------------------------------------------

proc genAddr(node: Node) =
  if node.kind == NdLvar:
    echo fmt"  lea rax, [rbp-{node.arg.offset}]"
    echo "  push rax"

proc load() =
  echo "  pop rax"
  echo "  mov rax, [rax]"
  echo "  push rax"

proc store() =
  echo "  pop rdi"
  echo "  pop rax"
  echo "  mov [rax], rdi"
  echo "  push rdi"

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
    echo "  pop rax"
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

  echo "  push rax"   # 式全体の結果を，スタックトップにプッシュ

proc codegen*(prog: Program) =
  echo ".intel_syntax noprefix"
  echo ".global main"
  echo "main:"

  echo "  push rbp"
  echo "  mov rbp, rsp"
  echo fmt"  sub rsp, {prog.stackSize}"

  var node = prog.node
  while true:
    if node == nil:
      break
    gen(node)
    node = node.next

  echo ".Lreturn:"
  echo "  mov rsp, rbp"
  echo "  pop rbp"
  echo "  ret"