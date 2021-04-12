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

# 現在着目しているトークン
var token: Token
var idx = 0

# 入力文字列準備
var input: seq[char]
if paramCount() != 1:
  quit("引数の個数が正しくありません．")
for i in commandLineParams()[0]:
  input.add(i)

# 現在のトークンが期待している記号の時は，トークンを１つ読み進めて真を返す． # それ以外の場合には偽を返す．
proc consume(op: char): bool =
  if token.kind != TkReserved or token.str[0] != op:
    return false
  token = token.next
  return true

# 現在のトークンが期待している記号の時には，トークンを１つ読み進める．# それ以外の場合にはエラー報告．
proc expect(op: char) =
  if token.kind != TkReserved or token.str[0] != op:
    quit(fmt"{op}ではありません．")
  token = token.next

# 現在のトークンが数値の場合，トークンを１つ読み進めてその数値を返す. # それ以外の倍にはエラーを報告する
proc expectNumber(): int =
  if token.kind != TkNum:
    quit("数ではありません．")
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

    if input[idx] == '+' or input[idx] == '-':
      cur = newToken(TkReserved, cur, $input[idx])
      inc(idx)
      continue

    if isDigit(input[idx]):
      var str = checkNum()
      cur = newToken(TkNum, cur, $input[idx])
      cur.val = parseInt(str)
      inc(idx)
      continue

    quit("トークナイズできません．")

  discard newToken(TkEof, cur, "\n")
  return head.next

# メイン関数
proc main() =
  token = tokenize()

  echo ".intel_syntax noprefix"
  echo ".globl _main"
  echo "_main:"

  echo fmt"  mov rax, {expectNumber()}"

  while not atEof():
    if consume('+'):
      echo fmt"  add rax, {expectNumber()}"
      continue

    expect('-')
    echo fmt"  sub rax, {expectNumber()}"

  echo "  ret"
  quit(0)

main()