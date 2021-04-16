import header
import strformat

# ローカル変数（連結リスト）
var locals: Lvar

#--------------------------------------------------------

# 現在のトークンが期待している記号の時は，トークンを１つ読み進めて真を返す． # それ以外の場合には偽を返す．
proc consume(op: string): bool =
  if token.kind != TkReserved or token.str != op:
    return false

  token = token.next
  return true

# 現在のトークンが期待している記号の時には，トークンを１つ読み進める．# それ以外の場合にはエラー報告．
proc expect(op: string) =
  if token.kind != TkReserved or token.str != op:
    errorAt(fmt"{op}ではありません．")

  token = token.next

# 現在のトークンが数値の場合，トークンを１つ読み進めてその数値を返す. # それ以外の倍にはエラーを報告する
proc expectNumber(): int =
  if token.kind != TkNum:
    errorAt("数ではありません．")

  var val = token.val
  token = token.next
  return val

# 終端チェック
proc atEof(): bool =
  return token.kind == TkEof

# 変数チェック
proc consumeIdent(): (Token, bool) =
  if token.kind != TkIdent:
    return (nil, false)

  var tmpTok: Token = token
  token = token.next
  return (tmpTok, true)

# 既に登録されている変数がチェック
proc findLvar(tok: Token): (Lvar, bool) =
  var tmp: Lvar = locals
  while true:
    if tmp == nil:
      break
    if tmp.name == tok.str:
      return (tmp, true)
    tmp = tmp.next
  return (tmp, false)

#オーバーロード--------------------------------------------------------------

# 単純なノード生成(ノードの型)
proc newNode(kind: NodeKind): Node =
  var node = new Node
  node.kind = kind
  return node

# 二項演算子用のノード生成（ノードの型，左辺ノード，右辺ノード）
proc newNode(kind: NodeKind, lhs: Node, rhs: Node): Node =
  var node: Node = newNode(kind)
  node.lhs = lhs
  node.rhs = rhs
  return node

# 単項演算子のノード(ノードの型，左辺ノード)
proc newNode(kind: NodeKind, lhs: Node): Node =
  var node: Node = newNode(kind)
  node.lhs = lhs
  return node

# 数値用のノード生成(数値)
proc newNode(val: int): Node =
  var node: Node = newNode(NdNum)
  node.val = val
  return node

# 変数用のノード(変数型)
proc newNode(arg: Lvar): Node =
  var node = newNode(NdLvar)
  node.arg = arg
  return node

# ローカル変数の連結リストに追加
proc pushLvar(name: string): Lvar =
  var arg = new Lvar
  arg.next = locals # ローカル変数の連結リストだけ右から左に生やしてくスタイル
  arg.name = name
  locals = arg
  return arg

#---------------------------------------------------------------------------

# 優先度低い順
proc program*(): Program
proc stmt(): Node
proc expr(): Node
proc assign(): Node
proc equality(): Node
proc relational(): Node
proc add(): Node
proc mul(): Node
proc unary(): Node
proc primary(): Node

# stmt*
proc program*(): Program =
  locals = nil # nilを設定

  # 連結リスト作成
  var head = new Node # ヒープにアロケート
  head.next = nil
  var cur = head # 参照のコピーだから中身は同じ

  # ノードを生成(連結リスト)
  while not atEof():
    cur.next = stmt()
    cur = cur.next

  # プログラム生成
  var prog =  new Program
  prog.node = head.next
  prog.locals = locals
  return prog

# "return" expr ";" | expr ";"
proc stmt(): Node =
  if consume("return"):
    var node = newNode(NdReturn, expr())
    expect(";")
    return node

  var node = newNode(NdExpr, expr())
  expect(";")
  return node

# assign
proc expr(): Node =
  return assign()

# equality ("=" assign)?
proc assign(): Node =
  var node = equality()

  if consume("="):
    node = newNode(NdAssign, node, assign()) # a=b=3とかしたいから，ここは右辺はasign()
  return node

# relational ("==" relational | "!=" relational)*
proc equality(): Node =
  var node: Node = relational()

  while true:
    if consume("=="):
      node = newNode(NdEq, node, relational())
    elif consume("!="):
      node = newNode(NdNe, node, relational())
    else:
      return node

# add ("<" add | "<=" add | ">" add | ">=" add)*
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

# mul ("+" mul | "-" mul)*
proc add(): Node =
  var node: Node = mul()

  while true:
    if consume("+"):
      node = newNode(NdAdd, node, mul())
    elif consume("-"):
      node = newNode(NdSub, node, mul())
    else:
      return node

# unary ("*" unary | "/" unary)*
proc mul(): Node =
  var node: Node = unary()

  while true:
    if consume("*"):
      node = newNode(NdMul, node, unary())
    elif consume("/"):
      node = newNode(NdDiv, node, unary())
    else:
      return node

# ("+" | "-")? primary
proc unary(): Node =
  if consume("+"):
    return primary()

  if consume("-"):
    return newNode(NdSub, newNode(0), unary()) # - - や - + などを許すために，ここはunary

  return primary()

#  "(" expr ")" | ident | num |
proc primary(): Node =
  if consume("("):
    var node = expr() # 再帰的に使うー
    expect(")")
    return node

  var tok = consumeIdent() # Token, bool が返る（tuple?）
  if tok[1]:
    var tmpLvar = findLvar(tok[0]) # Lvar, bool
    var lvar = tmpLvar[0]
    if not tmpLvar[1]:
      lvar = pushLvar(tok[0].str)
    return newNode(lvar)

  return newNode(expectNumber())
