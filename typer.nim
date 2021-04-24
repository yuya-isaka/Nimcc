#[
  ! ノードごとにそれぞれ値を持っている． その値が何の型なのか決めている.

  ! 値
  * kind, lhs, rhs
  * kind, lhs
  * val
  * lvar
]#
import header

#? int型生成
proc intType*(): Type =
  var ty = new Type
  ty.kind = TyInt
  return ty

#? Ptr型生成(baseとなる型を受け取る)
proc pointerTo*(base: Type): Type =
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
  
  for n in node.body:                                             # 配列の場合
    if n != nil:
      visit(n)

  var n = node.args                                               # 連結リストの場合
  while n != nil:
    visit(n)
    n = n.next

  #? 型付け
  case node.kind
  of NdNum, NdMul, NdDiv, NdEq, NdNe, NdL, NdLe, NdFuncall:       # 現状はこれらのノードはint型
    node.ty = intType()
    return
  of NdAdd:
    if node.rhs.ty.kind == TyPtr:                                 #! 3 + ptrみたいな式はあり得る
      var tmp = node.lhs
      node.lhs = node.rhs
      node.rhs = tmp
    if node.rhs.ty.kind == TyPtr:                                 #! ptr + ptr という式はない
      errorAt("invalid pointer arithmetic operands", node.tok)
    node.ty = node.lhs.ty                                         #! 右辺値がTyPtrだったらlhsとrhsを交換してるから自動的に，　右辺値がポインタなら右辺値の型，　右辺値が数値なら左辺値の型を入れる
                                                                  #! 加算はlhsとrhsが入れ替わっても問題ない(依存してない)
    return
  of NdSub:
    if node.rhs.ty.kind == TyPtr:                                 #! 3 - ptr みたいな式は存在しない
      errorAt("invalid pointer arithmetic operands", node.tok)
    node.ty = node.lhs.ty                                         #! 評価結果の型は，左辺の型に!!!!!依存する!!!!!
    return
  of NdAssign:
    node.ty = node.lhs.ty                                         #! 代入は「代入する値の型」に依存する！！！！
    return
  of NdAddr:
    node.ty = pointerTo(node.lhs.ty)                              #! node.lhs.ty(代入する値の型）をベース(依存)としたポインタ型を返す
    return
  of NdDeref:
    if node.lhs.ty.kind != TyPtr:                                 # お前はポインタじゃねえ
      errorAt("invalid pointer dereference", node.tok)
    node.ty = node.lhs.ty.base                                    #! このノードは，baseの型に依存する
    return
  of NdLvar:
    node.ty = node.lvar.ty                                        #! 変数ノードは，変数の型に依存する！！
    return                                                        #! ノードごとにそれぞれ値を持っている．その値が何の型なのか決めているのか
  else:
    discard

#? annotate AST nodes with types
proc addType*(prog: Function) =                                   #! ただの2重ループ(nodeの数だけvisit呼び出し)
  var fn = prog 
  while fn != nil:
    var node = fn.node
    while node != nil:
      visit(node)
      node = node.next
    fn = fn.next
