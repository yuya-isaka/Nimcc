
#[
  ? 目的：tokenを先頭からパースし，「Node型の連結リスト」に変換
  ? サブ目的：「LvarList型の連結リスト」を生成（変数用）
]#

import header
import typer
import strformat

var locals: LvarList                                            #! ローカル変数（連結リスト）
var globals: LvarList                                           #! グローバル変数（連結リスト）
var tokPrev: Token = nil                                        #! エラー表示用！　consumeで進める前のTokenを保持．　エラー表示に使える．　グローバル変数は使い所考えると有益
var cnt: int = 0

proc chirami(s: string): bool =
  if token.kind != TkReserved or token.str != s:
    return false
  return true

proc isTypeName(): bool =
  return chirami("int") or chirami("char")

proc consume(s: string): bool =
  if not chirami(s):
    return false
  tokPrev = token
  token = token.next
  return true

proc expect(s: string) =
  if not chirami(s):
    errorAt(fmt"expected, {s}", token)

  token = token.next

proc expectNumber(): int =
  if token.kind != TkNum:
    errorAt("数ではありません．", token)

  var val = token.val
  token = token.next
  return val

proc atEof(): bool =
  return token.kind == TkEof

# ?変数チェック1
proc consumeIdent(): (Token, bool) =
  if token.kind != TkIdent:
    return (nil, false)                                         # よくみたらここでnil返してるやんけ!!!

  var tmpTok: Token = token
  token = token.next
  return (tmpTok, true)

# ?変数チェック2
proc expectIdent(): string =
  if token.kind != TkIdent:
    errorAt("識別子ではありません", token)

  var val = token.str
  token = token.next
  return val

#? 既に登録されている変数がチェック
proc findLvar(tok: Token): (Lvar, bool) =                       #! tupleを返す(この設計は直さないといけん)
  #? ローカル変数チェク
  var vl: LvarList = locals
  while vl != nil:
    var lvar = vl.lvar
    if lvar.name == tok.str:
      return (lvar, true)
    vl = vl.next

  #? グローバル変数チェック
  vl = globals
  while vl != nil:
    var lvar = vl.lvar
    if lvar.name == tok.str:
      return (lvar, true)
  return (nil, false)                                           #! 一度バグって何も動かなくなった．ここでnilを返すように変更したのが良かった．（初期化されていないオブジェクトを返そうとしていた？）

#? 変数の連結リストに追加
proc pushLvar(name: string, ty: Type, isLocal: bool): Lvar =
  var lvar = new Lvar
  lvar.name = name
  lvar.ty = ty
  lvar.isLocal = isLocal

  var vl = new LvarList
  vl.lvar = lvar
  if isLocal:                          #! ローカル変数 
    vl.next = locals
    locals = vl
  else:                                #! グローバル変数
    vl.next = globals
    globals = vl
  return lvar

#? 多重ディスパッチ, オーバーロード
#? kind(全ての元となる), こいつ単体では何の値も持っていない
proc newNode(kind: NodeKind, tok: Token): Node =
  var node = new Node
  node.kind = kind
  node.tok = tok
  return node

#? kind, lhs, rhs
proc newNode(kind: NodeKind, lhs: Node, rhs: Node, tok: Token): Node =
  var node: Node = newNode(kind, tok)
  node.lhs = lhs
  node.rhs = rhs
  return node

#? kind, lhs
# NdReturn, NdExprStmt用 （;で終わるものを扱う)
proc newNode(kind: NodeKind, lhs: Node, tok: Token): Node =
  var node: Node = newNode(kind, tok)
  node.lhs = lhs
  return node

#? val
proc newNode(val: int, tok: Token): Node =
  var node: Node = newNode(NdNum, tok)
  node.val = val
  return node

#? lvar 
proc newNode(lvar: Lvar, tok: Token): Node =
  var node = newNode(NdLvar, tok)
  node.lvar = lvar
  return node

#! 優先度低い順
proc program*(): Program
proc function(): Function
proc basetype(): Type
proc globalLvar(): void
proc declaration(): Node
proc stmt(): Node
proc expr(): Node
proc assign(): Node
proc equality(): Node
proc relational(): Node
proc add(): Node
proc mul(): Node
proc unary(): Node
proc primaryArray(): Node
proc primary(): Node

proc isFunction(): bool =
  var tok = token
  discard basetype()
  var tmp = consumeIdent()
  var isFunc: bool = tmp[1] and consume("(")
  token = tok                                                         #! トークン元に戻す（関数かどうか事前にチェックするだけで， tokenは進めない）
  return isFunc

#? program = (global-lvar | function)*
proc program*(): Program =
  var head = new Function
  head.next = nil
  var cur: Function = head
  globals = nil

  while not atEof():
    if isFunction():
      cur.next = function()
      cur = cur.next
    else:
      globalLvar()
  
  var prog = new Program
  prog.globals = globals
  prog.fns = head.next
  return prog

#? basetype = ("char" | int") "*"*
proc basetype(): Type =                                                 
  var ty = new Type
  if consume("char"):
    ty = charType()
  else:
    expect("int")
    ty = intType()                                                      #! 現状char以外はint

  while consume("*"):
    ty = pointerType(ty)
  return ty

proc readTypeSuffix(base: var Type): Type =
  if not consume("["):
    return base
  var size = expectNumber()
  expect("]")
  base = readTypeSuffix(base)                                           #! int a[3][3] のような多次元配列に対応（再帰）
  return arrayType(base, size)

#? 関数の引数を読む！！
proc readFuncParam(): LvarList =
  var ty: Type = basetype()                                             #! 現状baseの型はintのみ
  var name = expectIdent()
  ty = readTypeSuffix(ty)                                               #! 配列の可能性を考慮

  var vl = new LvarList
  vl.lvar = pushLvar(name, ty, true)                                          #! 関数の引数をlocalsに追加
  return vl

#? 関数の引数を読む！！
proc readFuncParams(): LvarList =
  if consume(")"):
    return nil

  var head = readFuncParam()
  var cur = head

  while not consume(")"):
    expect(",")
    cur.next = readFuncParam()
    cur = cur.next

  return head

#? function = basetype ident "(" params? ")" "{" stmt* "}"
#? params   = param ("," param)*
#? param    = basetype ident
proc function(): Function =
  locals = nil                                                          # 関数内のローカル変数を保存するためのlocalsを初期化

  var fn = new Function
  discard basetype()                                                    #! 関数はintから始まると仮定してる．　basetype関数でtokenを進める
  fn.name = expectIdent()                                               # 全てのプログラムが関数の中だと考える．まずは関数名が来るはず．

  expect("(")
  fn.params = readFuncParams()                                          #! 最初に引数をローカル変数localsに追加しておく
  expect("{")

  var head = new Node                                                   # ヒープにアロケート
  head.next = nil
  var cur = head                                                        # 参照のコピーだから中身は同じ

  while not consume("}"):                                               #! ループでstatement(文)を生成
    cur.next = stmt()
    cur = cur.next

  fn.node = head.next                                                   #! Nodeの連結リストの先頭取得 -> codegenで抽象構文木を下りながら生成したいから
  fn.locals = locals                                                    #! 引数,ローカル変数の連結リストの先頭取得
  return fn

proc globalLvar() =
  var ty = basetype()
  var name = expectIdent()
  ty = readTypeSuffix(ty)
  expect(";")
  discard pushLvar(name, ty, false)

#? declaration = basetype ident ("[" num "]")* ("=" expr) ";"
proc declaration(): Node =
  var tok = token
  var ty = basetype()
  var name = expectIdent()
  ty = readTypeSuffix(ty)                                               #! 配列の可能性を考慮
  var lvar = pushLvar(name, ty, true)                                   #! 型付けされたローカル変数をlocalsに追加〜〜〜

  if consume(";"):                                                      #! 初期化されてない変数宣言
    return newNode(NdNull, tokPrev)

  expect("=")
  var lhs: Node = newNode(lvar, tok)                                    # 変数生成
  var rhs: Node = expr()
  expect(";")
  var node: Node = newNode(NdAssign, lhs, rhs, tok)                     #! 代入処理，　int a = 3;
  return newNode(NdExprStmt, node, tok)                                 #! 代入では評価結果をスタックに残す必要はない, 式の文

proc readExprStmt(): Node =
  var tok = token                                                       # この関数を呼び出すときはconsumeでtokenの連結が進められないから．現在参照している部分を見ればいい
  return newNode(NdExprStmt, expr(), tok)

#? stmt = "return" expr ";"
#?      | "if" "(" expr ")" stmt ("else" stmt)?
#?      | "while" "(" expr ")" stmt
#?      | "for" "(" expr? ";" expr? ";" expr? ")" stmt
#?      | "{" stmt* "}"
#?      | declaration
#?      | expr ";"
proc stmt(): Node =
  if consume("return"):
    var node = newNode(NdReturn, expr(), tokPrev)
    expect(";")
    return node

  if consume("if"):
    var node = newNode(NdIf, tokPrev)                                   # 左辺にノードを作るわけじゃないからnewNode(NdIf, expr())としない
    expect("(")
    node.cond = expr()                                                  #! Expression
    expect(")")
    node.then = stmt()                                                  #! !ifの中でifを使ってもいい, statement
    if consume("else"):
      node.els = stmt()
    return node

  if consume("while"):
    var node = newNode(NdWhile, tokPrev)
    expect("(")
    node.cond = expr()                                                  #! node.condのexpression(式）の評価結果はcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!
    expect(")")
    node.then = stmt()                                                  #! statement
    return node

  if consume("for"):
    var node = newNode(NdFor, tokPrev)
    expect("(")
    if not consume(";"):
      node.init = readExprStmt()                                        # !readExprStmtでラップしないと，スタックに評価結果が残ってしまう, 式の文！
      expect(";")
    if not consume(";"):
      node.cond = expr()                                                #! node.condはcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!
      expect(";")
    if not consume(")"):
      node.inc = readExprStmt()
      expect(")")
    node.then = stmt()                                                  #! このforでは，　ここのstatement（文)を返す．
    return node

  if consume("{"):
    var node = newNode(NdBlock, tokPrev)
    while not consume("}"):                                             #! ruiさんのとは違う実装だよー気をつけてなー未来の自分〜
      node.body.add(stmt())                                             #! 配列にしてみた．
    return node

  if isTypeName():                                                      #! 型名かチラ見！！！ （intかchar)
    return declaration()                                                #! intなら変数として格納!!!!

  var node = readExprStmt()                                             #! 式の文(a=3; とかとか)
  expect(";")                                                           #! 式にセミコロンがつくと文になる．
  return node

#? expr = assign
proc expr(): Node =
  return assign()

#? assign = equality ("=" assign)?
proc assign(): Node =
  var node = equality()

  if consume("="):
    node = newNode(NdAssign, node, assign(), tokPrev)                   #! a=b=3とかしたいから，ここは右辺はasign()
  return node

#? equality = relational ("==" relational | "!=" relational)*
proc equality(): Node =
  var node: Node = relational()

  while true:
    if consume("=="):
      node = newNode(NdEq, node, relational(), tokPrev)
    elif consume("!="):
      node = newNode(NdNe, node, relational(), tokPrev)
    else:
      return node

#? relational =  add ("<" add | "<=" add | ">" add | ">=" add)*
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

#? add = mul ("+" mul | "-" mul)*
proc add(): Node =
  var node: Node = mul()

  while true:
    if consume("+"):
      node = newNode(NdAdd, node, mul(), tokPrev)
    elif consume("-"):
      node = newNode(NdSub, node, mul(), tokPrev)
    else:
      return node

#? mul = unary ("*" unary | "/" unary)*
proc mul(): Node =
  var node: Node = unary()

  while true:
    if consume("*"):
      node = newNode(NdMul, node, unary(), tokPrev)
    elif consume("/"):
      node = newNode(NdDiv, node, unary(), tokPrev)
    else:
      return node

#? unary = ("+" | "-" | "&" | "*" )? unary 
#?         | primaryArray                                                 配列の演算子は特別，　a[3] -> *(a+3) に書き換える．
proc unary(): Node =
  if consume("+"):
    return unary()                                                        # これ忘れてた．．++とかもそりゃいいよね

  if consume("-"):
    return newNode(NdSub, newNode(0, tokPrev), unary(), tokPrev)          #! -- や -+ などを許すために，ここはunary

  if consume("&"):
    return newNode(NdAddr, unary(), tokPrev)

  if consume("*"):
    return newNode(NdDeref, unary(), tokPrev)

  return primaryArray()

#? primaryArray = primary ("[" expr "]")*
#? 配列の演算子は特別，　a[3] -> *(a+3) に書き換える．
proc primaryArray(): Node =
  var node = primary()                                                    # 配列だったらこのnodeの型がTyArrayになってる

  while consume("["):
    var exp = newNode(NdAdd, node, expr(), tokPrev)                       #! 左辺のnodeには識別子がくる． この左辺はNdLvarとして識別され，アドレス(RBP-offset)をゲットする．(これはロードしない) そのオフセットにexpr()で評価した数値を足すことで， 配列の要素にアクセスできる．
    expect("]")
    node = newNode(NdDeref, exp, tokPrev)                                 #! C言語では，配列は，ポインタ経由にアクセスする．
  
  return node

#? funcArgs =  "(" (assign ("," assign)*)? ")"
#? 関数の引数を評価し返す -> node.argsで持つ
proc funcArgs(): Node =
  if consume(")"):
    return nil
  
  var head = expr()                                                       # 元々assign()だったけど分かりにくいから， expr()にした
  var cur = head
  while consume(","):
    cur.next = expr()
    cur = cur.next
  expect(")")
  return head                                                             #! 評価結果をNodeの連結リストで返す．

#? primary =  "(" expr ")" | "sizeof" unary | ident func-args? | num |
proc primary(): Node =
  if consume("("):
    var node = expr()                                                     # 再帰的に使う
    expect(")")
    return node

  if consume("sizeof"):
    return newNode(NdSizeof, unary(), tokPrev)

  var tok = consumeIdent()                                                # Token, bool が返る（tuple）
  if tok[1]:

    #? 関数
    if consume("("):                                                      #! 「見知らぬ名前と，(」が続いていたら，それは関数と判定し，引数を評価して返す
      var node = newNode(NdFuncall, tokPrev)
      node.funcname = tok[0].str
      node.args = funcArgs()
      return node

    #? 変数
    var tmpLvar = findLvar(tok[0])                                        # LvarList, bool
    if not tmpLvar[1]:
                                                                          # tmpLvar[0] = pushLvar(tok[0].str)  # 昔はここで変数をlocalsに追加してた．　今は上の方でintを見つけた瞬間に格納している．
      errorAt("undefined variable", tok[0])                               #! ここで見たことない変数が来るのはおかしいからエラー
    return newNode(tmpLvar[0], tokPrev)                                   #! 変数生成
    
  #? 文字列リテラル
  var tmpTok = token
  if token.kind == TkStr:
    token = token.next

    var ty = arrayType(charType(), tmpTok.stringLiteral.len)                        #! 文字列リテラルはChar型の配列,  null終端分の文字列を+1で追加
    var lvar = pushLvar(fmt".L.data.{cnt}", ty, false)
    inc(cnt)
    lvar.stringLiteral = tmpTok.stringLiteral
    return newNode(lvar, tmpTok)

  #? 数値
  if token.kind != TkNum:
    errorAt("expected expression", token)
  return newNode(expectNumber(), tokPrev)