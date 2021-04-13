import os
import system
import strformat
import strutils

# トークンの種類
type
  TokenKind = enum
    TkReserved,   # 記号
    TkNum,        # 整数トークン
    TkEof         # 入力の終わりを表すトークン

# トークン型
type
  Token = ref object
    kind: TokenKind   # トークンの種類
    next: Token       # 次の入力トークン
    val: int          # kindがTkNumの場合，その数値
    str: string       # トークン文字列
    at: int           # 入力文字配列のうち，どこを指しているか（先頭インデックス）

# **********現在着目しているトークン***********
var token: Token

# 入力文字列準備
var idx = 0
var input: seq[char]
if paramCount() != 1:
  quit("引数の個数が正しくありません．")
for i in commandLineParams()[0]:
  input.add(i)

# エラー表示関数
proc errorAt(errorMsg: string) =
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
proc consume(op: char): bool =
  if token.kind != TkReserved or token.str[0] != op:
    return false
  token = token.next
  return true

# 現在のトークンが期待している記号の時には，トークンを１つ読み進める．# それ以外の場合にはエラー報告．
proc expect(op: char) =
  if token.kind != TkReserved or token.str[0] != op:
    errorAt(fmt"{op}ではありません．")
  token = token.next

# 現在のトークンが数値の場合，トークンを１つ読み進めてその数値を返す. # それ以外の倍にはエラーを報告する
proc expectNumber(): int =
  if token.kind != TkNum:
    errorAt("数ではありません．")
  var val = token.val
  token = token.next
  return val

proc atEof(): bool =
  return token.kind == TkEof

# 10以上の数値に対応
proc checkNum(): string =
  var tmpIdx = idx + 1
  var tmpStr = $input[idx]
  while len(input) > tmpIdx and isDigit(input[tmpIdx]):
    tmpStr = tmpStr & $(input[tmpIdx])
    inc(idx)
    inc(tmpIdx)
  return tmpStr

# 新しいトークンを作成してcurに繋げる
proc newToken(kind: TokenKind, cur: Token, str: string): Token =
  var tok = new Token
  tok.kind = kind
  tok.str = str
  tok.at = idx
  cur.next = tok
  return tok

# 入力文字列inputをトークナイズして返す
proc tokenize(): Token =
  var head: Token = new Token # 参照型のオブジェクト生成（ヒープ領域に確保）
  head.next = nil
  var cur = head # 参照のコピーなので，実体は同じもの

  while len(input) > idx:
    if isSpaceAscii(input[idx]):
      inc(idx)
      continue

    if input[idx] == '+' or input[idx] == '-' or input[idx] == '*' or input[idx] == '/' or input[idx] == '(' or input[idx] == ')':
      cur = newToken(TkReserved, cur, $input[idx])
      inc(idx)
      continue

    if isDigit(input[idx]):
      var str = checkNum()
      cur = newToken(TkNum, cur, $input[idx])
      cur.val = parseInt(str)
      inc(idx)
      continue

    errorAt("トークナイズできません．")

  discard newToken(TkEof, cur, "\n")
  return head.next

# ノードの種類（AST）
type
  NodeKind = enum
    NdAdd,  # +
    NdSub,  # -
    NdMul,  # *
    NdDiv,  # /
    NdNum   # 整数

# ノード型
type
  Node = ref object
    kind: NodeKind  # ノードの種類
    lhs: Node       # 左辺
    rhs: Node       # 右辺
    val: int        # kindがNdNumの場合の数値

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

proc expr(): Node

proc primary(): Node =
  if consume('('):
    var node: Node = expr()
    expect(')')
    return node

  return newNodeNum(expectNumber())

proc mul(): Node =
  var node: Node = primary()

  while true:
    if consume('*'):
      node = newNode(NdMul, node, primary())
    elif consume('/'):
      node = newNode(NdDiv, node, primary())
    else:
      return node

proc expr(): Node =
  var node: Node = mul()

  while true:
    if consume('+'):
      node = newNode(NdAdd, node, mul())
    elif consume('-'):
      node = newNode(NdSub, node, mul())
    else:
      return node

proc gen(node: Node) =
  if node.kind == NdNum:
    echo fmt"  push {node.val}"
    return

  gen(node.lhs)
  gen(node.rhs)

  echo "  pop rdi"
  echo "  pop rax"

  case node.kind
  of NdAdd:
    echo "  add rax, rdi"
  of NdSub:
    echo "  sub rax, rdi"
  of NdMul:
    echo "  imul rax, rdi"
  of NdDiv:
    echo "  cqo"
    echo "  idiv rdi"
  of NdNum:
    quit("何かがおかしい．")

  echo "  push rax"

# メイン関数
proc main() =
  token = tokenize()
  var node = expr()

  echo ".intel_syntax noprefix"
  echo ".globl _main"
  echo "_main:"

  gen(node)

  echo "  pop rax"  # スタックトップに式全体の値が残っているはずなので，RAXにロードする
  echo "  ret"      # 関数はRAXレジスタを返す
  quit(0)

main()