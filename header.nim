
#[
  * enum, object, グローバル変数, 入力文字列, などを管理
]#

import os
import strutils

# 入力文字列準備
var idx* = 0
var input*: seq[char]
if paramCount() != 1:
  quit("引数の個数が正しくありません．")
for i in commandLineParams()[0]:
  input.add(i)

#--------------------------------------------------------

# トークンの種類
type
  TokenKind* = enum
    TkReserved,   # 記号
    TkIdent,      # 識別子（変数）
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

# !現在着目しているトークン
var token*: Token

#----------------------------------------------------------

# ローカル変数の型(連結リスト)
type
  Lvar* = ref object
    next*: Lvar
    name*: string
    offset*: int

#-----------------------------------------------------------

# エラー表示関数(今微妙に使い勝手が悪い．ので後々書き換える)
proc errorAt*(errorMsg: string) =
  var tmp: string
  for i in input:
    tmp.add($i)
  echo tmp
  if token == nil: # 初期化されていない参照型Objectはnilとなる # 例外チェック # 本来はoption型とかを使うべき
    echo " ".repeat(idx) & "^"
  else:
    echo " ".repeat(token.at) & "^"
  # echo idx
  quit(errorMsg)

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
    NdAssign, # = 代入式
    NdLvar,   # 変数
    NdReturn,
    NdExpr,
    NdIf,

# ノード型
type
  Node* = ref object
    kind*: NodeKind  # ノードの種類
    next*: Node      # !次のノード, 複数のノードを配列(code)ではなく，連結リストで管理
    lhs*: Node       # 左辺
    rhs*: Node       # 右辺
    val*: int        # kindがNdNumの場合の数値
    arg*: Lvar       # kindがNdLvarの時

    # kindがNdIfの時
    cond*: Node
    then*: Node
    els*: Node

# プログラム型
type Program* = ref object
  node*: Node       # !複数ノード連結リストの先頭
  locals*: Lvar     # !ローカル変数連結リストの先頭
  stackSize*: int   # ローカル変数に用いたスタックサイズ

var program*: Program
