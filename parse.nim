
import header

#---------------------------------------------------------

# 二項演算子用のノード生成（左辺と右辺を持つ）
proc newNode(kind: NodeKind, lhs: Node, rhs: Node): Node =
  var node = new Node
  node.kind = kind
  node.lhs = lhs
  node.rhs = rhs
  return node

# 数値用のノード生成
proc newNodeNum(val: int): Node =
  var node = new Node
  node.kind = NdNum
  node.val = val
  return node

#---------------------------------------------------------

# 優先度低い順
proc expr*(): Node
proc equality(): Node
proc relational(): Node
proc add(): Node
proc mul(): Node
proc unary(): Node
proc primary(): Node

proc expr*(): Node =
  var node: Node = equality()
  return node

proc equality(): Node =
  var node: Node = relational()

  while true:
    if consume("=="):
      node = newNode(NdEq, node, relational())
    elif consume("!="):
      node = newNode(NdNe, node, relational())
    else:
      return node

proc relational(): Node =
  var node: Node = add()

  while true:
    if consume("<"):
      node = newNode(NdL, node, add())
    elif consume("<="):
      node = newNode(NdLe, node, add())
    elif consume(">"):
      node = newNode(NdL, add(), node)
    elif consume(">="):
      node = newNode(NdLe, add(), node)
    else:
      return node

proc add(): Node =
  var node: Node = mul()

  while true:
    if consume("+"):
      node = newNode(NdAdd, node, mul())
    elif consume("-"):
      node = newNode(NdSub, node, mul())
    else:
      return node

proc mul(): Node =
  var node: Node = unary()

  while true:
    if consume("*"):
      node = newNode(NdMul, node, unary())
    elif consume("/"):
      node = newNode(NdDiv, node, unary())
    else:
      return node

proc unary(): Node =
  if consume("+"):
    return primary()
  if consume("-"):
    return newNode(NdSub, newNodeNum(0), unary()) # - - や - + などを許すために，ここはunary

  return primary()

proc primary(): Node =
  if consume("("):
    var node: Node = expr() # 再帰的に使うー
    expect(")")
    return node

  return newNodeNum(expectNumber())
