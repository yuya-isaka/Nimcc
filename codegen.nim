
#[
  ? 目的：ノード連結リストと変数連結リストから「アセンブリ」を出力
]#

import header
import typer
import strformat

var labelSeq: int                                         #! 0で初期化してくれる
var funcname: string
var argreg1 = ["dil", "sil", "dl", "cl", "r8b", "r9b"]
var argreg8 = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]     #! 関数の引数の順番． x86-64, ABI仕様で決められている．　このルールに従わないと適切な機械語を生成できない

proc gen(node: Node)

#? 左辺値生成
proc genAddr(node: Node) =                                #! 左辺値生成（アドレス返すってこと）, C言語の左辺値は基本的にメモリのアドレスを指定する式
  case node.kind:
  of NdLvar:
    var lvar = node.lvar

    if lvar.isLocal:
      echo fmt"  lea rax, [rbp-{lvar.offset}]"             #! アドレス計算を行うが，メモリアクセスは行わず，アドレス計算の結果そのもの(アドレス）をraxに代入
      echo "  push rax"                                   #! raxにはアドレスが入ってる!!!重要だよ！！（評価結果じゃないんだよ！）
    else:
      echo fmt"  push offset {lvar.name}"                 #! グローバル変数の名前(lvar.name)をセット！ -> .data領域のアドレスを参照する？
    return
  of NdDeref:
    gen(node.lhs)                                         #! *p = 3 のようにデリファレンス経由で値を代入するときに対応するため， pのアドレスが生成されるように左辺値をコンパイル
    return
  else:
    errorAt("not an lvalue", node.tok)                    #! Token型を渡す設計にすることで， コードジェネレートの際のエラー位置を正確に確認できるようになった（本当か

proc genLval(node: Node) =
  if node.ty.kind == TyArray:                             #! 配列へのアクセスはポインタ経由じゃないとだめ
    errorAt("not an lvalue", node.tok)
  genAddr(node)

#? 変数取り出し
proc load(ty: Type) =                                            
  echo "  pop rax"

  if sizeType(ty) == 1:                                   #! char型の処理 
  # if ty.kind == TyChar:
    echo "  movsx rax, byte ptr [rax]"                    #! RAXが指しているアドレスから1バイトを読み込んでECXに入れる -> movでALにロードすると上位ビットが0に初期化されない -> 初期化されないと依存関係が64ビットの中に残ってしまい，並列化による恩恵を受けられなくなる
  else:
    echo "  mov rax, [rax]"
  echo "  push rax"

#? 変数格納
proc store(ty: Type) =                                            
  echo "  pop rdi"
  echo "  pop rax"

  if sizeType(ty) == 1:                                   #! TokenKindがTkCharか確認する方がいいのでは？　と思ったけど，ん？？　配列の時とか影響する？？  char型の処理だから，この記述というよりは，1バイトの時のアセンブリを出力している．そういう意味では1sizeType() == 1 との時というふうにした方が正しい
  # if ty.kind == TyChar:
    echo "  mov [rax], dil"
  else:
    echo "  mov [rax], rdi"
  echo "  push rdi"                                       #! NdAssignはNdExprStmtにラップされてるから，ここでpushしたものは，add rsp, 8で抜き取られる(ちゃんと取り除ける) -> なぜここでpush rdi をしているか？　スタックに一つ値を残すというスタックマシンを再現するため

proc gen(node: Node) =

  case node.kind                                          #! ここはreturnされるcase switch文
  of NdNull:
    return
  of NdNum:
    echo fmt"  push {node.val}"
    return                                                #! 計算しないNodeKindは全てリターン
  of NdExprStmt:
    gen(node.lhs)
    echo "  add rsp, 8"                                   #! pop raxをする代わり？ スタックポインタを上に8あげればpopしたのと同じ.
    return
  of NdLvar:                                              #? 変数利用
    genAddr(node)                                         #! 変数を右辺値として扱う場合は， まず左辺値として評価
    if node.ty.kind != TyArray:                           #! 配列だったら，スタックトップにアドレスを残す．
      load(node.ty)                                              #! スタックトップにある結果をアドレスとみなして，そのアドレスから値をロード
    return
  of NdAssign:                                            #? 代入
    genLval(node.lhs)                                     #! 左辺値, アドレス生成 (配列はエラー, ポインタ経由じゃないとだめ)
    gen(node.rhs)                                         #! 右辺値コンパイル， 評価結果を生成
    store(node.ty)                                               #! スタックトップに値があるから，それを左辺値のアドレスに代入
    return
  of NdAddr:                                              #? アドレス生成
    genAddr(node.lhs)                                     #! 左辺値としてコンパイル！！！！！！！ -> アドレスを計算してスタックに格納
    return
  of NdDeref:                                             #? デリファレンス
    gen(node.lhs)                                         #! 右辺値としてコンパイル. ->　何らかのアドレスを計算するコードに変換されるはず(そうでなければその結果をデリファレンスすることはできない．その場合はエラーにする） -> 最終的にgenAddrをどこかで呼び出すということ
    if node.ty.kind != TyArray:                           #! 配列だったら，スタックトップに評価結果を残す ->　配列は暗黙的にポインタに型変換される． -> 配列代入の時に，NdAssign->genLval()->genAddr(),NdDerefなので左辺gen()->NdAdd->gen()->NdLvar->genAddr(Ndlvar)(lea push)->gen()(push 1)->pop & pop->imul & add ->push rax->NdAssignのgen()-> push 3->NdAssgin(store())． その時この後addすることを見越して，load処理はせずに，アドレスだけをスタックに積んでおく必要がある．
      load(node.ty)                                              #! 何らかのアドレスを計算した後， スタックに評価結果を残す， それをロード
    return
  of NdIf:
    var label = labelSeq                                  #! ラベル番号はユニークにする
    inc(labelSeq)
    if node.els != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lelse{label}"
      gen(node.then)
      echo fmt"  jmp .Lend{label}"
      echo fmt".Lelse{label}:"                            #! :を付け忘れた覚書
      gen(node.els)
      echo fmt".Lend{label}:"
    else:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"  je .Lend{label}"
      gen(node.then)
      echo fmt".Lend{label}:"
    return
  of NdWhile:
    var label = labelSeq
    inc(labelSeq)
    echo fmt".Lbegin{label}:"
    gen(node.cond)
    echo "  pop rax"
    echo "  cmp rax, 0"
    echo fmt"   je .Lend{label}"
    gen(node.then)                                        #! node.thenはExprStmt()にラップされてるから，スタックトップに値は残らない
    echo fmt"   jmp .Lbegin{label}"
    echo fmt".Lend{label}:"
    return                                                #! return忘れてた覚書
  of NdFor:
    var label = labelSeq
    inc(labelSeq)
    if node.init != nil:
      gen(node.init)
    echo fmt".Lbegin{label}:"
    if node.cond != nil:
      gen(node.cond)
      echo "  pop rax"
      echo "  cmp rax, 0"
      echo fmt"   je .Lend{label}"
    gen(node.then)
    if node.inc != nil:
      gen(node.inc)
    echo fmt"   jmp .Lbegin{label}"
    echo fmt".Lend{label}:"
    return
  of NdBlock, NdStmtExpr:                                             # {}の中身はひたすら生成, body: seq[Node]
    for tmp in node.body:
      gen(tmp)                                            #! genで評価された結果がスタックに積まれるが，　ExprStmt()にラップされてるから，スタックトップに値は残らない
                                                          # -> echo "  pop rax" # readExprStmtのおかげでいらなくなった（便利です）
    return
  of NdFuncall:
    #* 関数の引数をローカル変数として格納
    var nargs = 0
    var arg = node.args                                   #! parseのprimary()内で作られたnode.argsの値を順番に評価し，アセンブリ生成する
    while arg != nil:
      gen(arg)                                            #! 順番にスタックにPUSH
      inc(nargs)
      arg = arg.next

    var i = nargs - 1
    while i >= 0:
      echo fmt"  pop {argreg8[i]}"                         #! 順番にスタックからPOP(ABI仕様) -> 引数それぞれ専用のレジスタに格納 ついでにRSPが関数の開始位置(RBP)まで戻る
      dec(i)                                              # これで空白のRBP以下が埋められた

    var label = labelSeq
    inc(labelSeq)
    echo "  mov rax, rsp"                                 #! 関数呼び出しの前にRSPは16の倍数じゃないとダメ！
    echo "  and rax, 15"                                  #! 関数を呼ぶ前にRSPを16の倍数になるように調整(PUSHやPOPはRSPを8バイト単位で変更するから、call命令を発行するときに必ずしもRSPが16の倍数になっているとは限らん)
                                                          #! and 15, 15 -> 15   and 16, 15 -> 0   and 17, 15 -> 1
    echo fmt"  jnz .Lcall{label}"                         #! 比較結果!=0で飛ぶ(RAXが16の倍数じゃない場合飛ぶ)
    echo "  mov rax, 0"                                   #! RAX初期化 -> 関数の呼び出し前はalが0になってないといけない -> 浮動小数点数の引数の個数をALに入れておくという決まりから，まだ浮動小数点数がない
    echo fmt"  call {node.funcname}"                      #! Makefile の gcc -static -o tmp tmp.s でスタティックにリンクし， libc標準ライブラリの関数(/usr/lib/x86_64-linux-gnu/libc.aのprintf.o)のコードが，実行ファイルにコピーしながら実行ファイル作成 だからcallで飛べる
    echo fmt"  jmp .Lend{label}"
    echo fmt".Lcall{label}:"                              #! jnz .Lcallで飛んでくる
    echo "  sub rsp, 8"                                   #! スタックを伸ばす(RSPが16の倍数になるように調整)
    echo "  mov rax, 0"                                   #! RAX初期化 -> 関数の呼び出し前はalが0になってないといけない
    echo fmt"  call {node.funcname}"
    echo "  add rsp, 8"                                   #! スタックを縮ませ元に戻す
    echo fmt".Lend{label}:"
    echo "  push rax"                                     #! 評価結果を格納
    return
  of NdReturn:
    gen(node.lhs)
    echo "  pop rax"                                      #! 関数全体の評価結果がスタックトップ(RSP)に入っている．　取り出してRAXにセット．
    echo fmt"  jmp .Lreturn.{funcname}"
    return
  else:
    discard                                               #! ここで捨てないと下の処理見れない

  gen(node.lhs)                                           #! これより下のNode型は，2つの値を使用する計算だから，まとめて上でgen(node.lhs),gen(node.rhs)している
  gen(node.rhs)

  echo "  pop rdi"
  echo "  pop rax"

  case node.kind                                          #? 計算&比較ふぇーーーーーーーーーず(returnせず，スタックに値を保存するだけ)
  of NdAdd:
    if node.ty.base != nil:                                                         #! ポインタだったら，型のサイズに合わせたオフセットを求める
      echo fmt"  imul rdi, {sizeType(node.ty.base)}"                                #! rdi = rdi * {}    
    echo "  add rax, rdi"
  of NdSub:
    if node.ty.base != nil:
      echo fmt"  imul rdi, {sizeType(node.ty.base)}"
    echo "  sub rax, rdi"
  of NdMul:
    echo "  imul rax, rdi"
  of NdDiv:
    echo "  cqo"
    echo "  idiv rdi"
  of NdEq:
    echo "  cmp rax, rdi"
    echo "  sete al"
    echo "  movzb rax, al"
  of NdNe:
    echo "  cmp rax, rdi"
    echo "  setne al"
    echo "  movzb rax, al"
  of NdL:
    echo "  cmp rax, rdi"
    echo "  setl al"
    echo "  movzb rax, al"
  of NdLe:
    echo "  cmp rax, rdi"
    echo "  setle al"
    echo "  movzb rax, al"
  else:
    discard

  echo "  push rax"                                       #! 式全体の結果を，スタックトップにプッシュ

proc emitData(prog: Program) =                            # data領域
  echo ".data"                                            # グローバル変数と文字列リテラルが置かれる場所

  var vl = prog.globals
  while vl != nil:
    var lvar = vl.lvar
    echo fmt"{lvar.name}:"                                # スタティックリンクしないと動かない
    if lvar.stringLiteral == "":
      echo fmt"  .zero {sizeType(lvar.ty)}"                 # 多分0で初期化ってことだと思う． (現状はグローバル変数は宣言しかできない)
      vl = vl.next
      continue      

    if lvar.stringLiteral != "":                               # ruiさんはこうやってbyteで指定
      for c in lvar.stringLiteral:
        echo fmt"  .byte {int(c)}"                        #! int()を入れないとだめ！！！ (charをASCII文字コードの数値に変換する)
          
    # エスケープ文字をstringから認識できなかったから（stringからASCII文字に変換できなかった） から，seq[char]を使った実装に変更
    # if lvar.stringLiteral != "":
    #   var tmpStr: string = "\""                             #? これ参考に実装 https://godbolt.org/#g:!((g:!((g:!((h:codeEditor,i:(j:1,lang:___c,source:'char+foo()+%7B+char+*x+%3D+%22abc%22%3B+return+x%5B0%5D%3B+%7D'),l:'5',n:'0',o:'C+source+%231',t:'0')),k:50,l:'4',n:'0',o:'',s:0,t:'0'),(g:!((h:compiler,i:(compiler:cg81,filters:(b:'0',binary:'1',commentOnly:'0',demangle:'0',directives:'0',execute:'1',intel:'1',trim:'0'),lang:___c,libs:!(),options:'-O0',source:1),l:'5',n:'0',o:'x86-64+gcc+8.1+(Editor+%231,+Compiler+%231)+C',t:'0')),k:50,l:'4',n:'0',o:'',s:0,t:'0')),l:'2',n:'0',o:'',t:'0')),version:4
    #   for c in lvar.stringLiteral:                               # abc -> "abc" とかじゃないとだめ
    #     tmpStr.add(c)
    #   tmpStr.add("\"")
    #   echo fmt"  .string {tmpStr}"

    vl = vl.next

proc loadArg(lvar: Lvar, idx: int) =                       #! スタックに確保した引数領域に， レジスタの値を代入する．　（レジスタの値は，main関数内で他の関数(addやらsubやら）を呼んだ際に，既にレジスタの中に書き出してある．)
  var sz = sizeType(lvar.ty)
  if sz == 1:
  # if lvar.ty.kind == TyChar:
    echo fmt"  mov [rbp-{lvar.offset}], {argreg1[idx]}"
  else:
    assert(sz == 8)
    echo fmt"   mov [rbp-{lvar.offset}], {argreg8[idx]}"

proc emitText(prog: Program) =                            # text領域
  echo ".text"                                            # プログラム（機械語，バイナリ）が置かれる場所です

  var fn = prog.fns
  while fn != nil:
    echo fmt".global {fn.name}"                           # macだと_mainで動く
    echo fmt"{fn.name}:"
    funcname = fn.name

    #? プロローグ
    echo "  push rbp"
    echo "  mov rbp, rsp"
    echo fmt"  sub rsp, {fn.stackSize}"                    #! 引数とローカル変数のスタック領域をRBPの下に確保

    var i = 0                                             #? ここは最初のmain()関数では呼ばれない（今のところ,main関数の引数の処理方法についてはまだ実装していない） -> gen()でのNdFuncallが先に呼ばれて，レジスタに値がセットされる．
    var vl = fn.params                                    #! ここで関数の引数に，レジスタに入っている値を代入するためにfn.paramsは使われる
    while vl != nil:                                      #? 最初のmain()関数では呼ばれない
      loadArg(vl.lvar, i)                                 #! 引数のためのスタック領域は確保されているが， 引数の中身がない． プログラムで渡した引数はx86-64では特定のレジスタの中に入っている．　そのレジスタの値をスタック上で確保していた引数の場所に代入することで，引数の値を参照できる． -> この後はローカル変数と同じようにアクセスすると値を得られる
      inc(i)
      vl = vl.next

    var node = fn.node                                    # 関数が持つノードが尽きるまでアセンブリ生成(連結リストだからこの書き方)
    while node != nil:
      gen(node)
      node = node.next

    #? エピローグ
    echo fmt".Lreturn.{funcname}:"
    echo "  mov rsp, rbp"                                 #! RSP(スタックトップ)をRBPの位置に移動
    echo "  pop rbp"                                      #! POPするとRSP兼RBPの値(上にRBPのアドレス)をスタックから取り出して， RBPにストア -> RBPが元に戻る(上のRBPに戻る) -> RSPがリターンアドレスを指す
    echo "  ret"                                          #! スタックからアドレスを一つポップ(リターンアドレスのはず），　そのアドレスにジャンプ

    fn = fn.next

proc codegen*(prog: Program) =
  echo ".intel_syntax noprefix"
  emitData(prog)
  emitText(prog)