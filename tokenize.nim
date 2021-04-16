import header
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

# アルファベットチェック
proc isAlpha(c: string): bool =
  return ("a" <= c and c <= "z") or ("A" <= c and c <= "Z") or c == "_"

# アルファベットと数値チェック
proc isAlnum(c: string): bool =
  return isAlpha(c) or ("0" <= c and c <= "9")

#---------------------------------------------------------------------------------------

# 入力文字列inputをトークナイズして返す
proc tokenize*(): Token =
  # 連結リスト作成
  var head: Token = new Token   # 参照型のオブジェクト生成（ヒープ領域に確保）
  head.next = nil
  var cur = head    # 参照のコピーなので，実体は同じもの

  while len(input) > idx:

    # 空白飛ばし
    if isSpaceAscii(input[idx]):
      inc(idx)
      continue

    # こっちを先("return")
    var tmpStr1: string = $input[idx]
    var tmp1: int = idx+1
    for _ in 1..5:
      if len(input) > tmp1:
        tmpStr1.add($input[tmp1])
        inc(tmp1)
    if tmpStr1 == "return" and not isAlnum($input[tmp1]):
      cur = newToken(TkReserved, cur, tmpStr1)
      idx += 6
      continue

    # こっちを先
    var tmpStr2: string = $input[idx]
    if len(input) > idx+1:
      tmpStr2.add($input[idx+1])
    if tmpStr2 == "==" or tmpStr2 == "!=" or tmpStr2 == "<=" or tmpStr2 == ">=":
      cur = newToken(TkReserved, cur, tmpStr2)
      idx += 2 # 2個インデックス進める
      continue

    # こっちを後
    if input[idx] == '+' or input[idx] == '-' or input[idx] == '*' or
      input[idx] == '/' or input[idx] == '(' or input[idx] == ')' or
      input[idx] == '<' or input[idx] == '>' or input[idx] == ';' or
      input[idx] == '=':
      cur = newToken(TkReserved, cur, $input[idx])
      inc(idx)
      continue

    # 識別子，変数
    if isAlpha($input[idx]):
      var tmpStr: string = $input[idx]
      inc(idx)
      while isAlnum($input[idx]):
        tmpStr.add($input[idx])
        inc(idx)
      cur = newToken(TkIdent, cur, tmpStr)
      continue

    # 数値
    if isDigit(input[idx]):
      var str: string = checkNum()
      cur = newToken(TkNum, cur, $input[idx])
      cur.val = parseInt(str)
      inc(idx)
      continue

    errorAt("トークナイズできません．")

  discard newToken(TkEof, cur, "\n")
  return head.next
