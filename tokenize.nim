
#[
  * 目的：入力文字列を「Token型の連結リスト」に変換
]#

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

# 予約語をチェック
proc checkReserved(cur: var Token): (string, bool) = # !tupleを返す

    # "return", "if", "else"
    var strList1 = ["return", "if", "else", "while", "for"] # !arrayになります
    for tmp in strList1:
      var tmpStr: string = $input[idx]
      var tmpIdx: int = idx+1
      for _ in 1..len(tmp)-1: # TODO間違えた箇所覚書
        if len(input) > tmpIdx:
          tmpStr.add($input[tmpIdx])
          inc(tmpIdx)
      if tmpStr == tmp and not isAlnum($input[tmpIdx]): # !returnxとかifxとかの記述を禁止する
        return (tmpStr, true)

    # こっちを先
    var strList2 = ["==", "!=", "<=", ">="]
    for tmp in strList2:
      var tmpStr: string = $input[idx]
      if len(input) > idx+1:
        tmpStr.add($input[idx+1])
      if tmpStr == tmp:
        return (tmpStr, true)

    # こっちを後
    var strList3 = ['+', '-', '*', '/', '(', ')', '<', '>', ';', '=']
    for tmp in strList3:
      if input[idx] == tmp:
        return ($input[idx], true)

    return ("", false)

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

    # 予約語
    var tmpStr = checkReserved(cur) # !TkReservedに関するトークン作成はこの関数で!
    if tmpStr[1]:
      cur = newToken(TkReserved, cur, tmpStr[0])
      idx += len(tmpStr[0]) # 読んだ文字列文インデックスを進める
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
