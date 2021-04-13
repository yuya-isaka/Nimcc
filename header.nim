import os
import strutils
import strformat

# 入力文字列準備
var idx* = 0
var input*: seq[char]
if paramCount() != 1:
  quit("引数の個数が正しくありません．")
for i in commandLineParams()[0]:
  input.add(i)

# トークンの種類
type
  TokenKind* = enum
    TkReserved,   # 記号
    TkNum,        # 整数トークン
    TkEof         # 入力の終わりを表すトークン

# トークン型
type
  Token* = ref object
    kind*: TokenKind   # トークンの種類
    next*: Token       # 次の入力トークン
    val*: int          # kindがTkNumの場合，その数値
    str*: string       # トークン文字列
    at*: int           # 入力文字配列のうち，どこを指しているか（先頭インデックス）

# **********現在着目しているトークン***********
var token*: Token
# ********************************************

# エラー表示関数
proc errorAt*(errorMsg: string) =
  var tmp: string
  for i in input:
    tmp.add($i)
  echo tmp
  if token == nil: # 初期化されていない参照型Objectはnilとなる # 例外チェック # 本来はoption型とかを使うべき
    echo " ".repeat(idx) & "^"
  else:
    echo " ".repeat(token.at) & "^"
  echo idx
  quit(errorMsg)

# 現在のトークンが期待している記号の時は，トークンを１つ読み進めて真を返す． # それ以外の場合には偽を返す．
proc consume*(op: string): bool =
  if token.kind != TkReserved or token.str != op:
    return false
  token = token.next
  return true

# 現在のトークンが期待している記号の時には，トークンを１つ読み進める．# それ以外の場合にはエラー報告．
proc expect*(op: string) =
  if token.kind != TkReserved or token.str != op:
    errorAt(fmt"{op}ではありません．")
  token = token.next

# 現在のトークンが数値の場合，トークンを１つ読み進めてその数値を返す. # それ以外の倍にはエラーを報告する
proc expectNumber*(): int =
  if token.kind != TkNum:
    errorAt("数ではありません．")
  var val = token.val
  token = token.next
  return val

proc atEof*(): bool =
  return token.kind == TkEof

# ------------------------------------------------------------------------------------

# ノードの種類（AST）
type
  NodeKind* = enum
    NdAdd,  # +
    NdSub,  # -
    NdMul,  # *
    NdDiv,  # /
    NdNum,  # 整数
    NdEq,   # ==
    NdNe,   # !=
    NdL,    # <
    NdLe,   # <=

# ノード型
type
  Node* = ref object
    kind*: NodeKind  # ノードの種類
    lhs*: Node       # 左辺
    rhs*: Node       # 右辺
    val*: int        # kindがNdNumの場合の数値

