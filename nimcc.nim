
import header
import parse
import codegen
import strutils

# 10以上の数値に対応
proc checkNum(): string =
  var tmpIdx = idx + 1
  var tmpStr = $input[idx]
  while len(input) > tmpIdx and isDigit(input[tmpIdx]):
    tmpStr.add($(input[tmpIdx]))
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
  var head: Token = new Token   # 参照型のオブジェクト生成（ヒープ領域に確保）
  head.next = nil
  var cur = head    # 参照のコピーなので，実体は同じもの

  while len(input) > idx:
    if isSpaceAscii(input[idx]):
      inc(idx)
      continue

    # こっちを先
    var tmpStr: string = $input[idx]
    if len(input) > idx+1:
      tmpStr.add($input[idx+1])
    if tmpStr == "==" or tmpStr == "!=" or tmpStr == "<=" or tmpStr == ">=":
      cur = newToken(TkReserved, cur, tmpStr)
      idx += 2 # 2個インデックス進める
      continue

    # こっちを後
    if input[idx] == '+' or input[idx] == '-' or input[idx] == '*' or
      input[idx] == '/' or input[idx] == '(' or input[idx] == ')' or
      input[idx] == '<' or input[idx] == '>':
      cur = newToken(TkReserved, cur, $input[idx])
      inc(idx)
      continue

    if isDigit(input[idx]):
      var str: string = checkNum()
      cur = newToken(TkNum, cur, $input[idx])
      cur.val = parseInt(str)
      inc(idx)
      continue

    errorAt("トークナイズできません．")

  discard newToken(TkEof, cur, "\n")
  return head.next


# メイン関数
proc main() =
  token = tokenize()
  var node = expr()

  echo ".intel_syntax noprefix"
  echo ".globl main"
  echo "main:"

  gen(node)

  echo "  pop rax"  # スタックトップに式全体の値が残っているはずなので，RAXにロードする
  echo "  ret"      # 関数はRAXレジスタを返す
  quit(0)

main()