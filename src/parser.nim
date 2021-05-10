

#[
   目的：tokenを先頭からパースし，「Node型の連結リスト」に変換
   サブ目的：「LvarList型の連結リスト」を生成（変数用）
]#


import header
import typer
import strformat


# ローカル変数，　関数引数，　LinkedList，　関数内のローカル変数を数珠繋ぎ，　引数も最初に繋がれる
var locals: LvarList                                            

# グローバル変数，　文字列リテラル，　LinkedList，　プログラム全体のグローバル変数を数珠繋ぎ，　文字列リテラルも繋がれる，　メモリ上の固定位置に存在（スタックではない），　メモリアドレスに直接アクセスするようにコンパイル
var globals: LvarList                                           

# 変数スコープ，　変数検索はこのscopeが対象，　「ブロック」と「文の式」でスコープを過去に戻す(スコープ抜けたら変数解放を実現），　定義する時に追加(右から左)，　実行するときに検索．
var scope: LvarList

# エラー表示用，　エラーが起きたトークンを知りたい，　トークンには文字列の先頭アドレスを記憶させている
var tokPrev: Token = nil                                        

# 文字列リテラルのラベル，　data領域にアセンブリで書くとき,それぞれの文字列リテラルの場所を示すラベルが必要
var cnt: int = 0

# 構造体スコープ，　構造体検索はこのtagScopeが対象，　「ブロック」と「文の式」でスコープを過去に戻す(スコープ抜けたら変数解放を実現），　定義する時に追加(右から左)，　実行するときに検索．
type TagScope = ref object
  next*: TagScope
  name*: string
  ty*: Type
var tagScope: TagScope


# 次トークン先読み　（予約文字列），　真偽値返却，　トークン進めない
proc chirami(s: string): bool =
  if token.kind != TkReserved or token.str != s:
    return false
  return true

# 次トークン先読み　（型名），　型名を期待する箇所で使用
proc isTypeName(): bool =
  return chirami("int") or chirami("char") or chirami("struct")

# 次トークン先読み　（終端），　終端を期待する箇所で使用　（programで全ての関数かグローバル変数を読み終わるまで）
proc atEof(): bool =
  return token.kind == TkEof

# 次トークン先読み　（予約文字列），　予約文字列かな〜?　真偽値返却，　トークン進める
proc consume(s: string): bool =
  if not chirami(s):
    return false
  tokPrev = token
  token = token.next
  return true

# 次トークン先読み　（予約文字列），　予約文字列じゃないとダメ!，　トークン進める
proc expect(s: string) =
  if not chirami(s):
    errorAt(fmt"expected, {s}", token)
  token = token.next

# 次トークン先読み　（数値・配列数），　数値関連じゃないとダメ！，　数値返却，　トークン進める
proc expectNumber(): int =
  if token.kind != TkNum:
    errorAt("数ではありません．", token)
  var val: int = token.val
  token = token.next
  return val

# 次トークン先読み　（変数名・関数名・構造体タグ名），　識別子かな〜?，　トークン・真偽値返却，　トークン進める
proc consumeIdent(): (Token, bool) =
  if token.kind != TkIdent:
    return (nil, false)                                   
  var tmpTok: Token = token
  token = token.next
  return (tmpTok, true)

# 次トークン先読み　（変数名・関数名・構造体タグ名），　識別子じゃないとダメ！，　識別文字列返却，　トークン進める
proc expectIdent(): string =
  if token.kind != TkIdent:
    errorAt("識別子ではありません", token)
  var val: string = token.str
  token = token.next
  return val

# 次トークン先読み　（文字列リテラル），　真偽値返却，　トークン進める
proc consumeStr(): bool =
  if token.kind != TkStr:
    return false
  token = token.next
  return true


# 連結済み変数検索，　ローカル変数・グローバル変数
proc findLvar(tokName: string): (Lvar, bool) =                       
  var vl: LvarList = scope                                      
  while vl != nil:
    if vl.lvar.name == tokName:
      return (vl.lvar, true)
    vl = vl.next
  return (nil, false)         

# 変数連結，　ローカル変数・関数引数・グローバル変数・文字列リテラル
proc pushLvar(name: string, ty: Type, isLocal: bool): Lvar =
  # 変数作成　（名前，　型，　ローカルか否か）
  var lvar: Lvar = new Lvar
  lvar.name = name
  lvar.ty = ty
  lvar.isLocal = isLocal
  # 変数LinkedList作成　（繋げるだけ）
  var vl: LvarList = new LvarList
  vl.lvar = lvar
  if isLocal:                           
    # ローカル変数LinkedList　（繋げるだけ）
    vl.next = locals
    locals = vl
  else:                               
    # グローバル変数LinkedList　（繋げるだけ）
    vl.next = globals
    globals = vl
  # スコープLinkedList作成　（繋げるだけ）
  var sc: LvarList = new LvarList
  sc.lvar = lvar
  sc.next = scope # LinkedListを辿るために「右から左」に連結
  scope = sc
  return lvar

# 連結済み構造体タグ検索，　見つけたTagScopeを返却　（現状sc.tokでも良い）
proc findTag(tokName: string): TagScope =
  var sc = tagScope
  while sc != nil:
    if sc.name == tokName:
      return sc
    sc = sc.next
  return nil

# 構造体タグ連結,　引数の「トークン名」と「型」を持つTagScopeを数珠繋ぎ
proc pushTagScope(tokName: string, ty: Type) =
  var sc: TagScope = new TagScope
  sc.next = tagScope
  sc.name = tokName
  sc.ty = ty
  tagScope = sc


# 起点ノード
# forとかそれぞれのnewNode作っても良いかも？
# params: NodeKind, Token
# return: Node
proc newNode(kind: NodeKind, tok: Token): Node =
  var node: Node = new Node
  node.kind = kind
  node.tok = tok
  return node

# 左辺右辺ノード
# params: NodeKind, Node, Node, Token
# return: Node
proc newNode(kind: NodeKind, lhs: Node, rhs: Node, tok: Token): Node =
  var node: Node = newNode(kind, tok)
  node.lhs = lhs
  node.rhs = rhs
  return node

# 左辺ノード (return, ExprStmt)
# params: NodeKind, Node, Token
# return: Node
proc newNode(kind: NodeKind, lhs: Node, tok: Token): Node =
  var node: Node = newNode(kind, tok)
  node.lhs = lhs
  return node

# 数値ノード
# params: int, Token
# return: Node
proc newNode(val: int, tok: Token): Node =
  var node: Node = newNode(NdNum, tok)
  node.val = val
  return node

# 変数ノード
# params: Lvar, Token
# return: Node
proc newNode(lvar: Lvar, tok: Token): Node =
  var node: Node = newNode(NdLvar, tok)
  node.lvar = lvar
  return node


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

proc structDecl(): Type

# 型
# params:
# return: Type
proc basetype(): Type =                                             
  if not isTypeName():
    errorAt("typename expected", token)

  var ty: Type = new Type
  if consume("char"):
    ty = charType()
  elif consume("int"):
    ty = intType()                                                  
  else:
    ty = structDecl()

  while consume("*"):
    ty = pointerType(ty)
  return ty

# 配列サフィックス
# params: var Type
# return: Type
proc readTypeSuffix(base: var Type): Type =
  if not consume("["):
    return base
  var size: int = expectNumber()
  expect("]")
  base = readTypeSuffix(base)   # multi demential
  return arrayType(base, size)

# 関数引数・子
# params:
# return: LvarList
proc readFuncParam(): LvarList =
  var ty: Type = basetype()                                         
  var name: string = expectIdent()
  ty = readTypeSuffix(ty)             
  var vl: LvarList = new LvarList
  vl.lvar = pushLvar(name, ty, true)  # locals list
  return vl

# 関数引数・親
# params:
# return: LvarList
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

# 事前関数チェック
# params:
# return: bool
proc isFunction(): bool =
  var tok: Token = token
  discard basetype()
  var tmp: (Token, bool) = consumeIdent()
  var isFunc: bool = tmp[1] and consume("(")
  token = tok   # undo token
  return isFunc

# グローバル変数登録
# params:
# return:
proc globalLvar() =
  var ty: Type = basetype()
  var name: string = expectIdent()
  ty = readTypeSuffix(ty)
  expect(";")
  discard pushLvar(name, ty, false)

# 式の文
# params:
# return: Node
proc readExprStmt(): Node =
  var tok: Token = token                
  return newNode(NdExprStmt, expr(), tok)

# 文の式
# params:
# return: Node
proc stmtExpr(): Node =
  var sc1: LvarList = scope    # scope variable
  var sc2: TagScope = tagScope # scope struct
  var node: Node = newNode(NdStmtExpr, tokPrev)  # このノードは式だから値を返す
  var cur: Node = new Node
  while not consume("}"): 
    cur = stmt()    # 最後の要素を取得したいから，　現在の値を更新し続ける
    node.body.add(cur)  # array
  expect(")")
  scope = sc1     # undo scope
  tagScope = sc2  # undo scope

  if cur.kind != NdExprStmt:                                                
    errorAt("stmt expr returning void is not supported", cur.tok)
  node.body[high(node.body)] = cur.lhs  # 取得した最後の値を入力しておく．　これがスタックトップに積まれる
  return node

# 引数評価
# params:
# return: Node (linked list)
proc funcArgs(): Node =
  if consume(")"):
    return nil
  var head: Node = expr()
  var cur: Node = head
  while consume(","):
    cur.next = expr()
    cur = cur.next
  expect(")")
  return head       

# 識別子定義
# params:
# return: Node
proc declaration(): Node =
  var tok: Token = token
  var ty: Type = basetype()

  # null
  if consume(";"):
    return newNode(NdNull, tok)

  # variable
  var name: string = expectIdent()
  # array
  ty = readTypeSuffix(ty)                             
  var lvar: Lvar = pushLvar(name, ty, true)           

  # null (初期化されていない変数)
  if consume(";"):                                      
    return newNode(NdNull, tokPrev)

  # assign
  expect("=")
  var lhs: Node = newNode(lvar, tok)                            
  var rhs: Node = expr()
  expect(";")
  var node: Node = newNode(NdAssign, lhs, rhs, tok)           
  # 代入では評価結果をスタックに残す必要はない, 式の文
  return newNode(NdExprStmt, node, tok)                                 

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

  # Read a struct tag
  var tag: (Token, bool) = consumeIdent()
  if (tag[1] and not chirami("{")):   # タグづけされてるものを使用しているかチェック, 使用してなかったら定義で呼び出されてる
    var sc: TagScope = findTag(tag[0].str)
    if sc == nil:
      errorAt("unknown struct type", tag[0])
    return sc.ty

  expect("{")

  # Read struct members
  var head = new Member
  head.next = nil
  var cur = head

  while not consume("}"):                            # 構造体の中身を読む(ループ)
    cur.next = structMember()
    cur = cur.next

  var ty = new Type
  ty.kind = TyStruct
  ty.members = head.next                            # 中身をmembers属性に追加

  var offset = 0
  var mem = ty.members
  while mem != nil:
    offset = alignTo(offset, mem.ty.align)          # オフセットの計算ではアライメントを噛ませる　アライメントの数は，型ごとに決まっている．64ビットアーキテクチャでは，
    mem.offset = offset                             # 先頭アドレスが8の倍数になるように設定すると， 1ワードに収まり，無駄なメモリアクセスが減る -> ８バイト境界にアライン(整列，位置合わせ)
    offset += sizeType(mem.ty)

    if ty.align < mem.ty.align:                     # 構造体全体のアライメントは大きい方に合わせる（charだけなら1のまま，int,ptrが入ると8になる）
      ty.align = mem.ty.align
    mem = mem.next

  if tag[1]:                            # タグ付きで定義されてたら，tagScopeに追加しておく
    pushTagScope(tag[0].str, ty)
  
  return ty

# マッピングされた関数(再帰下降構文解析----------------------------------------------------------------------------------------------------------------------------

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
    var node: Node = newNode(NdIf, tokPrev)                             # 左辺にノードを作るわけじゃないからnewNode(NdIf, expr())としない
    expect("(")
    node.cond = expr()                                                  # Expression
    expect(")")
    node.then = stmt()                                                  # ifの中でifを使ってもいい, statement
    if consume("else"):
      node.els = stmt()
    return node

  if consume("while"):
    var node: Node = newNode(NdWhile, tokPrev)
    expect("(")
    node.cond = expr()                                                  # node.condのexpression(式）の評価結果はcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!
    expect(")")
    node.then = stmt()                                                  # statement
    return node

  if consume("for"):
    var node: Node = newNode(NdFor, tokPrev)
    expect("(")
    if not consume(";"):
      node.init = readExprStmt()                                        # readExprStmtでラップしないと，スタックに評価結果が残ってしまう, 式の文！
      expect(";")
    if not consume(";"):
      node.cond = expr()                                                # node.condはcodegen内で，pop raxする予定があるから，readExprStmtでラップするのはだめ!!!!!!
      expect(";")
    if not consume(")"):
      node.inc = readExprStmt()
      expect(")")
    node.then = stmt()                                                  # このforでは，　ここのstatement（文)を返す．
    return node

  if consume("{"):                                                      # NdStmtExprと違って，値を返さない（文）
    var node: Node = newNode(NdBlock, tokPrev)
    var sc1: LvarList = scope                                                      # 現状のscope記憶
    var sc2: TagScope = tagScope
    while not consume("}"):                                             # ruiさんのとは違う実装だよー気をつけてなー未来の自分〜
      node.body.add(stmt())                                             # 配列にしてみた．
    scope = sc1                                                          # scopeが終わったら，新しく追加した変数リストは破棄する． -> scで書き戻し
    tagScope = sc2
    return node

  if isTypeName():                                                      # 型名かチラ見！！！ （intかchar)
    return declaration()                                                # intなら変数として格納!!!!

  var node: Node = readExprStmt()                                       # 式の文(a=3; とかとか)
  expect(";")                                                           # 式にセミコロンがつくと文になる．
  return node

proc expr(): Node =
  return assign()

proc assign(): Node =
  var node: Node = equality()

  if consume("="):
    node = newNode(NdAssign, node, assign(), tokPrev)                   # a=b=3とかしたいから，ここは右辺はasign()
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
    return newNode(NdSub, newNode(0, tokPrev), unary(), tokPrev)          # -- や -+ などを許すために，ここはunary

  if consume("&"):
    return newNode(NdAddr, unary(), tokPrev)

  if consume("*"):
    return newNode(NdDeref, unary(), tokPrev)

  return postFix()

proc postFix(): Node =
  var node: Node = primary()                                                    # 配列だったらこのnodeの型がTyArrayになってる, 構造体だったらTyStrになってる

  while true:
    # 配列アクセス
    if consume("["):
      var exp: Node = newNode(NdAdd, node, expr(), tokPrev)                       # 左辺のnodeには識別子がくる． この左辺はNdLvarとして識別され，アドレス(RBP-offset)をゲットする．(これはロードしない) そのオフセットにexpr()で評価した数値を足すことで， 配列の要素にアクセスできる．
      expect("]")
      node = newNode(NdDeref, exp, tokPrev)                                 # C言語では，配列は，ポインタ経由にアクセスする．
      continue

    # 構造体アクセス
    if consume("."):
      node = newNode(NdMember, node, tokPrev)                 # 左辺に追加しておく   NdMemberはアクセスするときに使う（逆にTyMemberは，メンバ変数の確認や，メンバ変数のオフセット計算に使われる）
      node.memberName = expectIdent()                         # アクセス先のメンバー変数名
      continue

    return node

proc primary(): Node =
  if consume("("):

    if consume("{"):                                                            # 文の式
      return stmtExpr()                                                         # 値を返すからこのprimaryに存在

    var node: Node = expr()                                                     # 丸括弧の中は式
    expect(")")
    return node

  if consume("sizeof"):
    return newNode(NdSizeof, unary(), tokPrev)

  var tok: (Token, bool) = consumeIdent()                                                # Token, bool が返る（tuple）
  if tok[1]:

    #? 関数
    if consume("("):                                                      # 「見知らぬ名前と，(」が続いていたら，それは関数と判定し，引数を評価して返す
      var node: Node = newNode(NdFuncall, tokPrev)
      node.funcname = tok[0].str
      node.args = funcArgs()
      return node

    #? 変数
    var tmpLvar: (Lvar, bool) = findLvar(tok[0].str)                                        # 変数は既に前方宣言されていて，localsに登録されているはず
    if not tmpLvar[1]:
                                                                          # tmpLvar[0] = pushLvar(tok[0].str)  # 昔はここで変数をlocalsに追加してた．　今は上の方でintを見つけた瞬間に格納している．
      errorAt("undefined variable", tok[0])                               # ここで見たことない変数が来るのはおかしいからエラー
    return newNode(tmpLvar[0], tokPrev)                                   # 変数生成
    
  #? 文字列リテラル
  var tmpTok: Token = token
  if consumeStr():
    var ty: Type = arrayType(charType(), tmpTok.stringLiteral.len)                        # 文字列リテラルはChar型の配列,  null終端分の文字列を+1で追加
    var lvar: Lvar = pushLvar(fmt".L.data.{cnt}", ty, false)                          # 文字列リテラルはデータ領域に確保
    inc(cnt)
    lvar.stringLiteral = tmpTok.stringLiteral
    return newNode(lvar, tmpTok)

  #? 数値
  if token.kind != TkNum:
    errorAt("expected expression", token)
  return newNode(expectNumber(), tokPrev)
