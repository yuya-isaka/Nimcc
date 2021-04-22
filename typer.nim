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
  of NdNum, NdMul, NdDiv, NdEq, NdNe, NdL, NdLe, NdLvar, NdFuncall:
    node.ty = intType()
    return
  of NdAdd:
    if node.rhs.ty.kind == TyPtr:
      var tmp = node.lhs
      node.lhs = node.rhs
      node.rhs = tmp
    if node.rhs.ty.kind == TyPtr:
      errorAt("invalid pointer arithmetic operands", node.tok)
    node.ty = node.lhs.ty
    return
  of NdSub:
    if node.rhs.ty.kind == TyPtr:
      errorAt("invalid pointer arithmetic operands", node.tok)
    node.ty = node.lhs.ty
    return
  of NdAssign:
    node.ty = node.lhs.ty
    return
  of NdAddr:
    node.ty = pointerTo(node.lhs.ty)
    return
  of NdDeref:
    if node.lhs.ty.kind == TyPtr:
      node.ty = node.lhs.ty.base
    else:
      node.ty = intType()
    return
  else:
    discard

proc addType*(prog: Function) =
  var fn = prog 
  while fn != nil:
    var node = fn.node
    while node != nil:
      visit(node)
      node = node.next
    fn = fn.next
