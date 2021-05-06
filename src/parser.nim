
#[
  ? 目的：tokenを先頭からパースし，「Node型の連結リスト」に変換
  ? サブ目的：「LvarList型の連結リスト」を生成（変数用）
]#

import header
import typer
import strformat

var locals: LvarList                                            #! ローカル変数（連結リスト）
var globals: LvarList                                           #! グローバル変数（連結リスト）
var scope: LvarList
var tokPrev: Token = nil                                        #! エラー表示用！　consumeで進める前のTokenを保持．　エラー表示に使える．　グローバル変数は使い所考えると有益
var cnt: int = 0

#! Token関係----------------------------------------------------------------------------------------------------------------------------

proc chirami(s: string): bool =
  if token.kind != TkReserved or token.str != s:
    return false
  return true

proc isTypeName(): bool =
  return chirami("int") or chirami("char") or chirami("struct")

proc atEof(): bool =
  return token.kind == TkEof

#! Token関係, token進める----------------------------------------------------------------------------------------------------------------------------

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

  var val: int = token.val
  token = token.next
  return val

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

  var val: string = token.str
  token = token.next
  return val

# ?文字列リテラルチェック
proc consumeStr(): bool =
  if token.kind != TkStr:
    return false
  token = token.next
  return true

#! 変数関係----------------------------------------------------------------------------------------------------------------------------

#? 既に登録されている変数がチェック
proc findLvar(tok: Token): (Lvar, bool) =                       #! tupleを返す(この設計は直さないといけん)

  # scope内の変数チェック
  var vl: LvarList = scope                                      #! scopeを調べる
  while vl != nil:
    if vl.lvar.name == tok.str:
      return (vl.lvar, true)
    vl = vl.next

  # #? ローカル変数チェク
  # var vl: LvarList = locals
  # while vl != nil:
  #   var lvar = vl.lvar
  #   if lvar.name == tok.str:
  #     return (lvar, true)
  #   vl = vl.next

  # #? グローバル変数チェック
  # vl = globals
  # while vl != nil:
  #   var lvar = vl.lvar
  #   if lvar.name == tok.str:
  #     return (lvar, true)
  #   vl = vl.next

  return (nil, false)                                           #! 一度バグって何も動かなくなった．ここでnilを返すように変更したのが良かった．（初期化されていないオブジェクトを返そうとしていた？）

#? 変数の連結リストに追加
proc pushLvar(name: string, ty: Type, isLocal: bool): Lvar =
  # 変数作成
  var lvar: Lvar = new Lvar
  lvar.name = name
  lvar.ty = ty
  lvar.isLocal = isLocal

  # どっちの連結リストに追加するか決定
  var vl: LvarList = new LvarList
  vl.lvar = lvar
  if isLocal:                          #! ローカル変数 
    vl.next = locals
    locals = vl
  else:                                #! グローバル変数
    vl.next = globals
    globals = vl

  # scope内に変数追加
  var sc: LvarList = new LvarList
  sc.lvar = lvar
  sc.next = scope                        # 右から左に生やしていく
  scope = sc

  return lvar

#! newNode ----------------------------------------------------------------------------------------------------------------------------

#? 多重ディスパッチ, オーバーロード
#? kind(全ての元となる), こいつ単体では何の値も持っていない
proc newNode(kind: NodeKind, tok: Token): Node =
  var node: Node = new Node
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
  var node: Node = newNode(NdLvar, tok)
  node.lvar = lvar
  return node

#! 生成規則->関数マッピング----------------------------------------------------------------------------------------------------------------------------

# 優先度低い順
proc program*(): Program
proc function(): Function
proc stmt(): Node
proc expr(): Node
proc assign(): Node
proc equality(): Node
proc relational(): Node
proc add(): Node
proc mul(): Node
proc unary(): Node
proc postFix(): Node
proc primary(): Node

#! 補助関数----------------------------------------------------------------------------------------------------------------------------

proc structDecl(): Type

#? basetype = ("char" | int" | struct-decl) "*"*
proc basetype(): Type =                                                   #? 識別子はここで型付け
  if not isTypeName():
    errorAt("typename expected", token)

  var ty: Type = new Type
  if consume("char"):
    ty = charType()
  elif consume("int"):
    ty = intType()                                                      #! 現状char以外はint
  else:
    ty = structDecl()

  while consume("*"):
    ty = pointerType(ty)
  return ty

proc readTypeSuffix(base: var Type): Type =
  if not consume("["):
    return base
  var size: int = expectNumber()
  expect("]")
  base = readTypeSuffix(base)                                           #! int a[3][3] のような多次元配列に対応（再帰）
  return arrayType(base, size)

#? 関数の引数を読む！！
proc readFuncParam(): LvarList =
  var ty: Type = basetype()                                             #! 現状baseの型はintのみ
  var name: string = expectIdent()
  ty = readTypeSuffix(ty)                                               #! 配列の可能性を考慮

  var vl: LvarList = new LvarList
  vl.lvar = pushLvar(name, ty, true)                                          #! 関数の引数をlocalsに追加
  return vl

#? 関数の引数を読む！！
proc readFuncParams(): LvarList =
  if consume(")"):
    return nil

  var head: LvarList = readFuncParam()
  var cur: LvarList = head

  while not consume(")"):
    expect(",")
    cur.next = readFuncParam()
    cur = cur.next

  return head

proc isFunction(): bool =
  var tok: Token = token
  discard basetype()
  var tmp: (Token, bool) = consumeIdent()
  var isFunc: bool = tmp[1] and consume("(")
  token = tok                                                         #! トークン元に戻す（関数かどうか事前にチェックするだけで， tokenは進めない）
  return isFunc

proc globalLvar() =
  var ty: Type = basetype()
  var name: string = expectIdent()
  ty = readTypeSuffix(ty)
  expect(";")
  discard pushLvar(name, ty, false)

proc readExprStmt(): Node =
  var tok: Token = token                                                       # この関数を呼び出すときはconsumeでtokenの連結が進められないから．現在参照している部分を見ればいい
  return newNode(NdExprStmt, expr(), tok)

proc stmtExpr(): Node =
  var sc: LvarList = scope                                              # 現状のscope
  var node: Node = newNode(NdStmtExpr, tokPrev)                               #! NdBlockと違って最後の値を返す！！！！！(途中にreturnがあればそれを返す) -> 式だから
  var cur: Node = new Node
  while not consume("}"):                                             #! ruiさんのとは違う実装だよー気をつけてなー未来の自分〜
    cur = stmt()
    node.body.add(cur)                                                    #! 配列にしてみた．
  expect(")")

  scope = sc                                                             # scope書き戻し     

  if cur.kind != NdExprStmt:                                                
    errorAt("stmt expr returning void is not supported", cur.tok)
  # cur = cur.lhs
  node.body[high(node.body)] = cur.lhs                                    #! 最後は左辺を入力することで, NdExprStmtから抜ける（add rsp, 8)をしないようにする
  return node

#? funcArgs =  "(" (assign ("," assign)*)? ")"      関数の引数を評価し返す -> node.argsで持つ
proc funcArgs(): Node =
  if consume(")"):
    return nil
  
  var head: Node = expr()                                                       # 元々assign()だったけど分かりにくいから， expr()にした
  var cur: Node = head
  while consume(","):
    cur.next = expr()
    cur = cur.next
  expect(")")
  return head                                                             #! 評価結果をNodeの連結リストで返す．

proc declaration(): Node =
  var tok: Token = token
  var ty: Type = basetype()
  var name: string = expectIdent()
  ty = readTypeSuffix(ty)                                               #! 配列の可能性を考慮
  var lvar: Lvar = pushLvar(name, ty, true)                                   #! 型付けされたローカル変数をlocalsに追加〜〜〜

  if consume(";"):                                                      #! 初期化されてない変数宣言
    return newNode(NdNull, tokPrev)

  expect("=")
  var lhs: Node = newNode(lvar, tok)                                    # 変数生成
  var rhs: Node = expr()
  expect(";")
  var node: Node = newNode(NdAssign, lhs, rhs, tok)                     #! 代入処理，　int a = 3;
  return newNode(NdExprStmt, node, tok)                                 #! 代入では評価結果をスタックに残す必要はない, 式の文

#? 構造体メンバー作成
proc structMember(): Member =
  var mem = new Member
  mem.ty = basetype()                               # 型取得
  mem.name = expectIdent()                          # 変数名
  mem.ty = readTypeSuffix(mem.ty)                   # suffix取得（配列なら[]）
  expect(";")
  return mem

#? 構造体作成 -> 型がメンバー変数を持つ（後々，typer.nimでnode.memberに移る）
proc structDecl(): Type =
  expect("struct")
  expect("{")

  var head = new Member
  head.next = nil
  var cur = head

  while not consume("}"):                            # 構造体の中身を読む
    cur.next = structMember()
    cur = cur.next

  var ty = new Type
  ty.kind = TyStruct
  ty.members = head.next                            # 中身をmembers属性に追加

  var offset = 0
  var mem = ty.members
  while mem != nil:
    mem.offset = offset                             # それぞれのメンバー変数のオフセット計算
    offset += sizeType(mem.ty)
    mem = mem.next
  
  return ty

#! マッピングされた関数(再帰下降構文解析----------------------------------------------------------------------------------------------------------------------------

#? program = (function | global-lvar)*
#? function = basetype ident "(" params? ")" "{" stmt* "}"
#?          params   = param ("," param)*
#?          param    = basetype ident
#? stmt = "return" expr ";"
#?      | "if" "(" expr ")" stmt ("else" stmt)?
#?      | "while" "(" expr ")" stmt
#?      | "for" "(" expr? ";" expr? ";" expr? ")" stmt
#?      | "{" stmt* "}"
#?      | declaration
#?      | expr ";"
#?      declaration = basetype ident ("[" num "]")* ("=" expr) ";"
#? expr = assign
#? assign = equality ("=" assign)?
#? equality = relational ("==" relational | "!=" relational)*
#? relational =  add ("<" add | "<=" add | ">" add | ">=" add)*
#? add = mul ("+" mul | "-" mul)*
#? mul = unary ("*" unary | "/" unary)*
#? unary = ("+" | "-" | "&" | "*" )? unary 
#?         | postFix                                                 配列の演算子は特別，　a[3] -> *(a+3) に書き換える．
#? postFix = primary ("[" expr "]" | "." ident)*                                 配列の演算子は特別，　a[3] -> *(a+3) に書き換える．
#? primary =  "(" expr ")" | "sizeof" unary | ident func-args? | num |

proc program*(): Program =
  # 関数の連結リスト作成
  var head: Function = new Function
  head.next = nil
  var cur: Function = head
  globals = nil

  # 関数かグローバル変数
  while not atEof():
    if isFunction():
      cur.next = function()
      cur = cur.next
    else:
      globalLvar()
  
  # プログラム作成
  var prog: Program = new Program
  prog.globals = globals
  prog.fns = head.next
  return prog

proc function(): Function =
  locals = nil                                                          # 関数内のローカル変数を保存するためのlocalsを初期化

  # 関数作成
  var fn: Function = new Function
  discard basetype()                                                    #! 関数はintから始まると仮定してる．　basetype関数でtokenを進める
  fn.name = expectIdent()                                               # 全てのプログラムが関数の中だと考える．まずは関数名が来るはず．

  # 引数読み込み
  expect("(")
  fn.params = readFuncParams()                                          #! 最初に引数をローカル変数localsに追加しておく
  expect("{")

  # 関数の中身， Node連結リスト作成
  var head: Node = new Node                                                   # ヒープにアロケート
  head.next = nil
  var cur: Node = head                                                        # 参照のコピーだから中身は同じ

  while not consume("}"):                                               #! ループでstatement(文)を生成
    cur.next = stmt()
    cur = cur.next

  fn.node = head.next                                                   #! Nodeの連結リストの先頭取得 -> codegenで抽象構文木を下りながら生成したいから
  fn.locals = locals                                                    #! 引数,ローカル変数の連結リストの先頭取得
  return fn

proc stmt(): Node =
  if consume("return"):
    var node: Node = newNode(NdReturn, expr(), tokPrev)
    expect(";")
    return node

  if consume("if"):
    var node: Node = newNode(NdIf, tokPrev)                                   # 左辺にノードを作るわけじゃないからnewNode(NdIf, expr())としない
    expect("(")
    node.cond = expr()                                                  #! Expression
    expect(")")
    node.then = stmt()                                                  #! !ifの中でifを使ってもいい, statement
    if consume("else"):
      node.els = stmt()
    return node

  if consume("while"):
    var node: Node = newNode(NdWhile, tokPrev)
    expect("(")
    node.cond = expr()                                                  #! node.condのexpression(式）の評価結果はcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!
    expect(")")
    node.then = stmt()                                                  #! statement
    return node

  if consume("for"):
    var node: Node = newNode(NdFor, tokPrev)
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

  if consume("{"):                                                      #! NdStmtExprと違って，値を返さない（文）
    var node: Node = newNode(NdBlock, tokPrev)
    var sc: LvarList = scope                                                      # 現状のscope記憶
    while not consume("}"):                                             #! ruiさんのとは違う実装だよー気をつけてなー未来の自分〜
      node.body.add(stmt())                                             #! 配列にしてみた．
    scope = sc                                                          # scope書き戻し
    return node

  if isTypeName():                                                      #! 型名かチラ見！！！ （intかchar)
    return declaration()                                                #! intなら変数として格納!!!!

  var node: Node = readExprStmt()                                             #! 式の文(a=3; とかとか)
  expect(";")                                                           #! 式にセミコロンがつくと文になる．
  return node

proc expr(): Node =
  return assign()

proc assign(): Node =
  var node: Node = equality()

  if consume("="):
    node = newNode(NdAssign, node, assign(), tokPrev)                   #! a=b=3とかしたいから，ここは右辺はasign()
  return node

proc equality(): Node =
  var node: Node = relational()

  while true:
    if consume("=="):
      node = newNode(NdEq, node, relational(), tokPrev)
    elif consume("!="):
      node = newNode(NdNe, node, relational(), tokPrev)
    else:
      return node

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

proc add(): Node =
  var node: Node = mul()

  while true:
    if consume("+"):
      node = newNode(NdAdd, node, mul(), tokPrev)
    elif consume("-"):
      node = newNode(NdSub, node, mul(), tokPrev)
    else:
      return node

proc mul(): Node =
  var node: Node = unary()

  while true:
    if consume("*"):
      node = newNode(NdMul, node, unary(), tokPrev)
    elif consume("/"):
      node = newNode(NdDiv, node, unary(), tokPrev)
    else:
      return node

proc unary(): Node =
  if consume("+"):
    return unary()                                                        # これ忘れてた．．++とかもそりゃいいよね

  if consume("-"):
    return newNode(NdSub, newNode(0, tokPrev), unary(), tokPrev)          #! -- や -+ などを許すために，ここはunary

  if consume("&"):
    return newNode(NdAddr, unary(), tokPrev)

  if consume("*"):
    return newNode(NdDeref, unary(), tokPrev)

  return postFix()

proc postFix(): Node =
  var node: Node = primary()                                                    # 配列だったらこのnodeの型がTyArrayになってる, 構造体だったらTyStrになってる？

  while true:
    # 配列アクセス
    if consume("["):
      var exp: Node = newNode(NdAdd, node, expr(), tokPrev)                       #! 左辺のnodeには識別子がくる． この左辺はNdLvarとして識別され，アドレス(RBP-offset)をゲットする．(これはロードしない) そのオフセットにexpr()で評価した数値を足すことで， 配列の要素にアクセスできる．
      expect("]")
      node = newNode(NdDeref, exp, tokPrev)                                 #! C言語では，配列は，ポインタ経由にアクセスする．
      continue

    # 構造体アクセス
    if consume("."):
      node = newNode(NdMember, node, tokPrev)                 # 左辺に追加しておく
      node.memberName = expectIdent()                         # アクセス先のメンバー変数名
      continue

    return node

proc primary(): Node =
  if consume("("):
    if consume("{"):                                                            #? 文の式
      return stmtExpr()
    var node: Node = expr()                                                     # 丸括弧の中は式
    expect(")")
    return node

  if consume("sizeof"):
    return newNode(NdSizeof, unary(), tokPrev)

  var tok: (Token, bool) = consumeIdent()                                                # Token, bool が返る（tuple）
  if tok[1]:

    #? 関数
    if consume("("):                                                      #! 「見知らぬ名前と，(」が続いていたら，それは関数と判定し，引数を評価して返す
      var node: Node = newNode(NdFuncall, tokPrev)
      node.funcname = tok[0].str
      node.args = funcArgs()
      return node

    #? 変数
    var tmpLvar: (Lvar, bool) = findLvar(tok[0])                                        #? 変数は既に前方宣言されていて，localsに登録されているはず
    if not tmpLvar[1]:
                                                                          # tmpLvar[0] = pushLvar(tok[0].str)  # 昔はここで変数をlocalsに追加してた．　今は上の方でintを見つけた瞬間に格納している．
      errorAt("undefined variable", tok[0])                               #! ここで見たことない変数が来るのはおかしいからエラー
    return newNode(tmpLvar[0], tokPrev)                                   #! 変数生成
    
  #? 文字列リテラル
  var tmpTok: Token = token
  if consumeStr():
    var ty: Type = arrayType(charType(), tmpTok.stringLiteral.len)                        #! 文字列リテラルはChar型の配列,  null終端分の文字列を+1で追加
    var lvar: Lvar = pushLvar(fmt".L.data.{cnt}", ty, false)
    inc(cnt)
    lvar.stringLiteral = tmpTok.stringLiteral
    return newNode(lvar, tmpTok)

  #? 数値
  if token.kind != TkNum:
    errorAt("expected expression", token)
  return newNode(expectNumber(), tokPrev)