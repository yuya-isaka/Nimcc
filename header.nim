
#[
  ? enum, object, グローバル変数, 入力文字列, ライブラリ関数(errorAt) などを管理
]#

import os
import strutils

#? 入力文字列準備
var idx* = 0
var input*: seq[char]
if paramCount() != 1:
  quit("引数の個数が正しくありません．")
for i in commandLineParams()[0]:
  input.add(i)


#? トークン
type TokenKind* = enum
    TkReserved,           # 記号
    TkIdent,              # 識別子（変数）
    TkNum,                # 整数トークン
    TkEof                 # 入力の終わりを表すトークン

type Token* = ref object
    kind*: TokenKind      # トークンの種類
    next*: Token          # 次の入力トークン
    val*: int             # kindがTkNumの場合，その数値
    str*: string          # トークン文字列
    at*: int              # 入力文字配列のうち，どこを指しているか（先頭インデックス）

var token*: Token = nil

proc errorAt*(errorMsg: string, tok: Token) = 
  # エラー表示関数（メッセージとトークンを受け取って，そのトークンの位置に値を挿入する)
  var tmp: string
  for i in input:
    tmp.add($i)
  echo tmp
  if tok == nil:
    echo " ".repeat(idx) & "^"
  else:
    echo " ".repeat(tok.at) & "^"
  quit(errorMsg)


#? 型
type TypeKind* = enum
    TyInt,
    TyPtr,
    TyArray

type Type* = ref object
    kind*: TypeKind       # 型の種類
    base*: Type           # TyPtrの時, 対象変数
    arraySize*: int       # typerで配列のサイズを計算するときに使う


#? 変数
type Lvar* = ref object
    name*: string
    offset*: int                # offset from RBP
    ty*: Type
    isLocal*: bool              #! ローカル変数かグローバル変数か

type LvarList* = ref object
    next*: LvarList
    lvar*: Lvar


#? ノード
type NodeKind* = enum
    NdAdd,                      # +
    NdSub,                      # -
    NdMul,                      # \*
    NdDiv,                      # /
    NdNum,                      # 整数
    NdEq,                       # ==
    NdNe,                       # \!=
    NdL,                        # <
    NdLe,                       # <=
    NdAssign,                   # = 代入式
    NdLvar,                     # 変数
    NdReturn,                   # return
    NdExprStmt,                 # 式の文
    NdIf,                       # if
    NdWhile,                    # while
    NdFor,                      # for
    NdBlock,                    # compound statement
    NdFuncall,                  # function
    NdAddr,                     # pointer &
    NdDeref,                    # pointer *
    NdNull,                     # NULL
    NdSizeof                    # sizeof 

type Node* = ref object
    kind*: NodeKind             # ノードの種類
    next*: Node                 # 次のノード(連結リストで管理)
    lhs*: Node                  # 左辺
    rhs*: Node                  # 右辺
    val*: int                   # kindがNdNumの場合の数値
    lvar*: Lvar                 # kindがNdLvarの時

    # kindがNdIf,NdWhileの時
    cond*: Node
    then*: Node
    els*: Node

    # kindがNdForの時
    init*: Node
    inc*: Node

    # kindがNdBlockの時
    body*: seq[Node]

    # kindがNdFuncallの時
    funcname*: string
    args*: Node

    # エラー表示用
    tok*: Token

    # 型情報
    ty*: Type


#? 関数
type Function* = ref object
  next*: Function
  name*: string
  params*: LvarList
  node*: Node                             #! 複数ノード連結リストの先頭
  locals*: LvarList                       #! ローカル変数連結リストの先頭
  stackSize*: int                         # ローカル変数に用いたスタックサイズ


#? プログラム
type Program* = ref object
    globals*: LvarList                    #! 連結リスト
    fns*: Function                        #! 連結リスト