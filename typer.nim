import header

proc intType(): Type =
  var ty = new Type
  ty.kind = TyInt
  return ty

proc pointerTo(base: Type): Type =
  var ty = new Type
  ty.kind = TyPtr
  ty.base = base
  return ty

proc visit(node: Node) =
  if node == nil:
    return

  visit(node.lhs)
  visit(node.rhs)
  visit(node.cond)
  visit(node.then)
  visit(node.els)
  visit(node.init)
  visit(node.inc)
  
  for n in node.body:   # 配列の場合
    if n != nil:
      visit(n)

  var n = node.args     # 連結リストの場合
  while n != nil:
    visit(n)
    n = n.next

  case node.kind
  of NdNum, NdMul, NdDiv, NdEq, NdNe, NdL, NdLe, NdLvar, NdFuncall:   # 現状は全部intで扱う
    node.ty = intType()
    return
  #! 加減算はポインタが絡むからしっかり書く
  of NdAdd:
    if node.rhs.ty.kind == TyPtr:
      var tmp = node.lhs
      node.lhs = node.rhs
      node.rhs = tmp
    if node.rhs.ty.kind == TyPtr:
      errorAt("invalid pointer arithmetic operands", node.tok)
    node.ty = node.lhs.ty   #! 右辺値がTyPtrだったらlhsとrhsを交換してるから自動的に，　右辺値がポインタなら右辺値の型，　右辺値が数値なら左辺値の型を入れる
                            #! 加算はlhsとrhsが入れ替わっても問題ない
    return
  of NdSub:   #! ???
    if node.rhs.ty.kind == TyPtr:
      errorAt("invalid pointer arithmetic operands", node.tok)
    node.ty = node.lhs.ty
    return
  of NdAssign:
    node.ty = node.lhs.ty
    return
  of NdAddr:
    node.ty = pointerTo(node.lhs.ty)    # baseとなるty型を渡す
    return
  of NdDeref:
    if node.lhs.ty.kind == TyPtr:   # ポインタならbaseを渡す
      node.ty = node.lhs.ty.base
    else:
      node.ty = intType()
    return
  else:
    discard

#! annotate AST nodes with types
proc addType*(prog: Function) =
  var fn = prog 
  while fn != nil:
    var node = fn.node
    while node != nil:
      visit(node)
      node = node.next
    fn = fn.next
