
#[
  * 目的：トークン列を先頭からパースし，「Node型の連結リスト」に変換
  * サブ目的：「Lvar型の連結リスト」を生成（変数用）
]#

import header
import strformat

#! ローカル変数（連結リスト）
var locals: LvarList
var tokPrev: Token = nil #! エラー表示用！　consumeで進める前のTokenを保持．　エラー表示に使える．　グローバル変数は使い所考えると有益

#--------------------------------------------------------

# 現在のトークンが期待している記号の時は，トークンを１つ読み進めて真を返す． # それ以外の場合には偽を返す．
proc consume(op: string): bool =
  if token.kind != TkReserved or token.str != op:
    return false

  tokPrev = token
  token = token.next
  return true

# 現在のトークンが期待している記号の時には，トークンを１つ読み進める．# それ以外の場合にはエラー報告．
proc expect(op: string) =
  if token.kind != TkReserved or token.str != op:
    errorAt(fmt"{op}ではありません．", token)

  token = token.next

# 現在のトークンが数値の場合，トークンを１つ読み進めてその数値を返す. # それ以外の倍にはエラーを報告する
proc expectNumber(): int =
  if token.kind != TkNum:
    errorAt("数ではありません．", token)

  var val = token.val
  token = token.next
  return val

# 終端チェック
proc atEof(): bool =
  return token.kind == TkEof

# 変数チェック1
proc consumeIdent(): (Token, bool) =
  if token.kind != TkIdent:
    return (nil, false)   #! よくみたらここでnil返してるやんけ!!!

  var tmpTok: Token = token
  token = token.next
  return (tmpTok, true)

# 変数チェック2
proc expectIdent(): string =
  if token.kind != TkIdent:
    errorAt("識別子ではありません", token)

  var val = token.str
  token = token.next
  return val

#-----------------------------------------------------------------------

# 既に登録されている変数がチェック
proc findLvar(tok: Token): (Lvar, bool) = #! tupleを返す(この設計は直さないといけん)
  var vl: LvarList = locals
  while vl != nil:
    var lvar = vl.lvar
    if lvar.name == tok.str:
      return (lvar, true)
    vl = vl.next
  return (nil, false)   #! 一度バグって何も動かなくなった．ここでnilを返すように変更したのが良かった．（初期化されていないオブジェクトを返そうとしていた？）

# ローカル変数の連結リストに追加
proc pushLvar(name: string): Lvar =
  var lvar = new Lvar
  lvar.name = name

  var vl = new LvarList
  vl.lvar = lvar
  vl.next = locals
  locals = vl
  return lvar

#! オーバーロード--------------------------------------------------------------

# 単純なノード生成(ノードの型)
proc newNode(kind: NodeKind, tok: Token): Node =
  var node = new Node
  node.kind = kind
  node.tok = tok
  return node

# 二項演算子用のノード生成（ノードの型，左辺ノード，右辺ノード）
proc newNode(kind: NodeKind, lhs: Node, rhs: Node, tok: Token): Node =
  var node: Node = newNode(kind, tok)
  node.lhs = lhs
  node.rhs = rhs
  return node

# 現在は，NdReturnとNdExprStmt用のノード（;で終わるものを扱う，左辺だけのノード）(ノードの型，左辺ノード)
proc newNode(kind: NodeKind, lhs: Node, tok: Token): Node =
  var node: Node = newNode(kind, tok)
  node.lhs = lhs
  return node

# 数値用のノード生成(数値)
proc newNode(val: int, tok: Token): Node =
  var node: Node = newNode(NdNum, tok)
  node.val = val
  return node

# 変数用のノード(変数型)
proc newNode(arg: Lvar, tok: Token): Node =
  var node = newNode(NdLvar, tok)
  node.arg = arg
  return node

#---------------------------------------------------------------------------

# 優先度低い順
proc program*(): Function
proc function(): Function
proc stmt(): Node
proc expr(): Node
proc assign(): Node
proc equality(): Node
proc relational(): Node
proc add(): Node
proc mul(): Node
proc unary(): Node
proc primary(): Node

# function*
proc program*(): Function =
  var head = new Function
  head.next = nil
  var cur: Function = head

  while not atEof():
    cur.next = function()
    cur = cur.next
  
  return head.next

proc readFuncParams(): LvarList =
  if consume(")"):
    return nil

  # *引数をローカル変数localsに追加しておく（最初に）
  var head = new LvarList
  head.lvar = pushLvar(expectIdent())
  var cur = head

  while not consume(")"):
    expect(",")
    cur.next = new LvarList
    cur.next.lvar = pushLvar(expectIdent())
    cur = cur.next

  return head

# ident "(" params? ")" "{" stmt* "}"
# params = ident ("," ident)*
proc function(): Function =
  locals = nil # 関数内のローカル変数を保存するためのlocalsを初期化

  var fn = new Function
  fn.name = expectIdent() # 全てのプログラムが関数の中だと考える．まずは関数名が来るはず．

  expect("(")
  fn.params = readFuncParams() #! 最初に!!!引数をローカル変数localsに追加しておく
  expect("{")

  # Node用連結リスト作成
  var head = new Node # ヒープにアロケート
  head.next = nil
  var cur = head #! 参照のコピーだから中身は同じ

  # ノードを生成(連結リスト)
  while not consume("}"):
    cur.next = stmt()
    cur = cur.next

  # プログラム生成
  fn.node = head.next #! 連結リストの先頭を取得
  fn.locals = locals
  return fn

proc readExprStmt(): Node =  #! 左辺値？？？
  var tok = token #! ???この関数を呼び出すときはconsumeでtokenの連結が進められないから．現在参照している部分を見ればいい
  return newNode(NdExprStmt, expr(), tok)

#[
  "return" expr ";" 
  | "if" "(" expr ")" stmt ("else" stmt)?
  | "while" "(" expr ")" stmt
  | "for" "(" expr? ";" expr? ";" expr? ")" stmt
  | "{" stmt* "}"
  | expr ";"
]# 
proc stmt(): Node =
  if consume("return"):
    var node = newNode(NdReturn, expr(), tokPrev)
    expect(";")
    return node

  if consume("if"):
    var node = newNode(NdIf, tokPrev) # 左辺にノードを作るわけじゃないからnewNode(NdIf, expr())としない
    expect("(")
    #todo 式！！！！！！！!!!!!!!!!!!!!!!!!!!
    node.cond = expr()    #! node型のcondメンバ変数に値を格納
    expect(")")
    #todo 文！！！！！！!!!!!!!!!!!!!!!!!1
    node.then = stmt()    # !ifの中でifを使ってもいい
    if consume("else"):
      node.els = stmt()
    return node

  if consume("while"):
    var node = newNode(NdWhile, tokPrev)
    expect("(")
    #todo 式！！！！！！！!!!!!!!!!!!!!!!!!!!
    node.cond = expr() #!!!!!!! node.condはcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!1
    expect(")")
    #todo 文！！！！！！!!!!!!!!!!!!!!!!!
    node.then = stmt()
    return node

  if consume("for"):
    var node = newNode(NdFor, tokPrev)
    expect("(")
    if not consume(";"):
      node.init = readExprStmt()    # !readExprStmtでラップしないと，スタックに不要な値が残ってしまう, 式の文！
      #! ここのforのifでは最終的にnode.then = stmt() の値を返すため(この値は結局255らへんのreadExprStmt()にラップされてる）
      #! この式の文の値は括っとかないとスタックから解放されない．
      expect(";")
    if not consume(";"):
      node.cond = expr()    #!!!!!!! node.condはcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!1
      expect(";")
    if not consume(")"):
      node.inc = readExprStmt()
      expect(")")
    node.then = stmt()
    return node

  if consume("{"):
    var node = newNode(NdBlock, tokPrev)
    while not consume("}"): #! ruiさんのとは違う実装だよー気をつけてなー未来の自分〜
      node.body.add(stmt())   #! 配列にしてみた．
    return node

  #todo 式の文!!!!!!!!!!!! ->  -> だからpopしないといけない．　スタックに残る！　add rsp, 8する！！！
  #todo 式にセミコロンがつく．　セミコロンがつくと文になる．
  var node = readExprStmt() #! 式の文(基本的にここの中で評価される． a=3; とかとか)
  expect(";")
  return node

# assign
proc expr(): Node =
  return assign()

# equality ("=" assign)?
proc assign(): Node =
  var node = equality()

  if consume("="):
    node = newNode(NdAssign, node, assign(), tokPrev) # a=b=3とかしたいから，ここは右辺はasign()
  return node

# relational ("==" relational | "!=" relational)*
proc equality(): Node =
  var node: Node = relational()

  while true:
    if consume("=="):
      node = newNode(NdEq, node, relational(), tokPrev)
    elif consume("!="):
      node = newNode(NdNe, node, relational(), tokPrev)
    else:
      return node

# add ("<" add | "<=" add | ">" add | ">=" add)*
proc relational(): Node =
  var node: Node = add()

  while true:
    if consume("<"):
      node = newNode(NdL, node, add(), tokPrev)
    elif consume("<="):
      node = newNode(NdLe, node, add(), tokPrev)
    elif consume(">"):
      node = newNode(NdL, add(), node, tokPrev)
    elif consume(">="):
      node = newNode(NdLe, add(), node, tokPrev)
    else:
      return node

# mul ("+" mul | "-" mul)*
proc add(): Node =
  var node: Node = mul()

  while true:
    if consume("+"):
      node = newNode(NdAdd, node, mul(), tokPrev)
    elif consume("-"):
      node = newNode(NdSub, node, mul(), tokPrev)
    else:
      return node

# unary ("*" unary | "/" unary)*
proc mul(): Node =
  var node: Node = unary()

  while true:
    if consume("*"):
      node = newNode(NdMul, node, unary(), tokPrev)
    elif consume("/"):
      node = newNode(NdDiv, node, unary(), tokPrev)
    else:
      return node

# unary = ("+" | "-" | "&" | "*" )? unary | primary
proc unary(): Node =
  if consume("+"):
    return unary()  #! これ忘れてた．．++とかもそりゃいいよね

  if consume("-"):
    return newNode(NdSub, newNode(0, tokPrev), unary(), tokPrev) #! -- や -+ などを許すために，ここはunary

  if consume("&"):
    return newNode(NdAddr, unary(), tokPrev)

  if consume("*"):
    return newNode(NdDeref, unary(), tokPrev)

  return primary()

# "(" (assign ("," assign)*)? ")"
proc funcArgs(): Node =
  if consume(")"):
    return nil
  
  var head = assign()
  var cur = head
  while consume(","):
    cur.next = assign()
    cur = cur.next
  expect(")")
  return head

#  "(" expr ")" | ident func-args? | num |
proc primary(): Node =
  if consume("("):
    var node = expr() # 再帰的に使う
    expect(")")
    return node

  var tok = consumeIdent() # Token, bool が返る（tuple）
  if tok[1]:
    if consume("("):
      var node = newNode(NdFuncall, tokPrev)
      node.funcname = tok[0].str
      node.args = funcArgs()
      return node
    var tmpLvar = findLvar(tok[0]) # LvarList, bool
    if not tmpLvar[1]:
      tmpLvar[0] = pushLvar(tok[0].str)
    return newNode(tmpLvar[0], tokPrev)

  if token.kind != TkNum:
    errorAt("expected expression", token)
  return newNode(expectNumber(), tokPrev)
