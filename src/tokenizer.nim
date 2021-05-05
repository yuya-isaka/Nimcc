
#[
  ? 目的：入力文字列を「Token型の連結リスト」に変換
]#

import header
import strutils

# 10以上の数値に対応(要修正)
proc checkNum(): string =
  var tmpIdx = idx + 1
  var tmpStr = $input[idx]
  while len(input) > tmpIdx and isDigit(input[tmpIdx]):
    tmpStr.add($(input[tmpIdx]))
    inc(idx)
    inc(tmpIdx)
  return tmpStr

# アルファベットチェック
proc isAlpha(c: string): bool =
  return ("a" <= c and c <= "z") or ("A" <= c and c <= "Z") or c == "_"

# アルファベットと数値チェック
proc isAlnum(c: string): bool =
  return isAlpha(c) or ("0" <= c and c <= "9")

# 予約語をチェック
proc checkReserved(): (string, bool) =                  #! tupleを返す

    # "return", "if", "else"
    var strList1 = ["return", "if", "else", "while", "for", "int", "sizeof", "char", "struct"]    #! arrayになる
    for tmp in strList1:
      var tmpStr: string = $input[idx]
      var tmpIdx: int = idx+1
      for _ in 1..<len(tmp):                                         # 間違えた箇所覚書
        if len(input) > tmpIdx:
          tmpStr.add($input[tmpIdx])
          inc(tmpIdx)
      if tmpStr == tmp and not isAlnum($input[tmpIdx]):               #! returnxとかifxとかの記述を禁止する
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
    var strList3 = ['+', '-', '*', '/', '(', ')', '<', '>', ';', '=', '{', '}', ',', '&', '[', ']', '.']
    for tmp in strList3:
      if input[idx] == tmp:
        return ($input[idx], true)

    return ("", false)

proc getEscapeChar(c: char): char =
  case c
  of 'a': return '\a'
  of 'b': return '\b'
  of 't': return '\t'
  of 'n': return '\n'
  of 'v': return '\v'
  of 'f': return '\f'
  of 'r': return '\r'
  of 'e': return char(27)
  of '0': return char(0)
  else: return c

proc strstr(): bool =
  while len(input) > idx and len(input) > idx+1:
    var tmpStr = $input[idx] & $input[idx+1]
    if tmpStr == "*/":
      idx += 2
      return true
    inc(idx)
  return false

proc checkComment(): bool =
  var tmpStr = $input[idx]
  if len(input) > idx + 1:
    tmpStr.add($input[idx+1])

  if tmpStr == "//":
    idx += 2

    var tmpChar: char
    while tmpChar != '\n':
      if input[idx] == '\\':
        tmpChar = getEscapeChar(input[idx+1])                   #! 無理矢理 \n を改行に入れて対応
      inc(idx)
    inc(idx)
    return true

  if tmpStr == "/*":
    idx += 2
    if not strstr():
      errorAt("unclosed block comment", token)
    return true

  return false

# 新しいトークンを作成してcurに繋げる
proc newToken(kind: TokenKind, cur: Token, str: string): Token =
  var tok = new Token
  tok.kind = kind
  tok.str = str
  tok.at = idx
  cur.next = tok
  return tok

# オーバーロード（文字列リテラル）
proc newToken(kind: TokenKind, cur: Token, stringLiteral: seq[char]): Token =
  var tok = new Token
  tok.kind = kind
  tok.str = ""
  tok.at = idx
  cur.next = tok
  tok.stringLiteral = stringLiteral
  return tok

# 入力文字列inputをトークナイズして返す
proc tokenize*(): Token =

  var head: Token = new Token                       # 参照型のオブジェクト生成（ヒープ領域に確保）
  head.next = nil
  var cur = head                                    # 参照のコピーなので，実体は同じもの

  while len(input) > idx:

    #? 空白飛ばし
    if isSpaceAscii(input[idx]):
      inc(idx)
      continue

    #? コメント
    var commentFlag = checkComment()
    if commentFlag:
      continue

    #? 予約語(こいつは先に)
    var tmpStr = checkReserved()                 #! TkReservedに関するトークン作成はこの関数で!
    if tmpStr[1]:
      cur = newToken(TkReserved, cur, tmpStr[0])
      idx += len(tmpStr[0])                         # 読んだ文字列文インデックスを進める
      continue

    #? 文字列リテラル seq[char]時代
    if input[idx] == '\"':
      inc(idx)
      var tmpStr: seq[char]
      while input[idx] != '\"':
        if len(input) <= idx:
          errorAt("unclosed string literal", token)

        if input[idx] == '\\':
          inc(idx)
          tmpStr.add(getEscapeChar(input[idx]))
        else:
          tmpStr.add(input[idx])
        inc(idx)
      tmpStr.add("\0")                                #? null terminate
      cur = newToken(TkStr, cur, tmpStr)
      inc(idx)
      continue

    # #? 文字列リテラル string時代
    # if input[idx] == '\"':
    #   inc(idx)
    #   var tmpStr: string
    #   while input[idx] != '\"':
    #     tmpStr.add($input[idx])
    #     inc(idx)
    #     if len(input) <= idx:
    #       errorAt("unclosed string literal", token)
    #   # tmpStr.add("\0")                                #? null terminate
    #   cur = newToken(TkStr, cur, tmpStr)
    #   inc(idx)
    #   continue

    #? 識別子 (ここでprintfなどのlibcに含まれる関数も読み込む)
    if isAlpha($input[idx]):
      var tmpStr: string = $input[idx]
      inc(idx)
      while isAlnum($input[idx]):
        tmpStr.add($input[idx])
        inc(idx)
      cur = newToken(TkIdent, cur, tmpStr)
      continue

    #? 数値
    if isDigit(input[idx]):
      var str: string = checkNum()
      cur = newToken(TkNum, cur, $input[idx])
      cur.val = parseInt(str)
      inc(idx)
      continue

    errorAt("トークナイズできません．", token)                                    # nil のtokenが渡されて， errorAtでnil用の処理が走る

  discard newToken(TkEof, cur, "\n")
  return head.next