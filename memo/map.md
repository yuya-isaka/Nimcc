# nimcc.nim

- トークナイズ(字句解析)

- パース(構文解析,lexer)

- それぞれの関数内の引数＋ローカル変数たちにオフセット値を設定

- ついでに全体のスタックサイズも保存

- コード生成

# header.nim

- 入力文字列をinput(seq[char])に格納，インデックスidxも準備

- TokenKind
    - 記号
    - 識別子(変数)
    - 整数
    - 終端

- Token型(連結リスト)
    - TokenKind
    - 次のToken型
    - 数値
    - 文字列
    - 入力文字列のうち指している先頭場所(いつか使えるといいな)

- グローバル変数トークン(token)

- Lvar型
    - 名前
    - オフセット

- LvarList型(連結リスト)
    - 次のLvarList型
    - Lvar型

- エラー表示関数(Tokeを渡すことで，codegenでのエラーも感知)

- NodeKind
    - \+
    - \-
    - \*
    - /
    - 整数
    - ==
    - !=
    - <
    - <=
    - =
    - 変数
    - return
    - ExprStmt(式と文)
    - if
    - while
    - for
    - block, 複文
    - function
    - ポインタ，アドレス
    - ポインタ，デリファレンス

- Node型（連結リスト）
    - NodeKind
    - 次のNode型
    - 左辺Node型
    - 右辺Node型
    - 数値
    - Lvar型(arg)
    - Node型(If,cond)
    - Node型(If,then)
    - Node型(If,els)
    - Node型(For,init)
    - Node型(For,inc)
    - Node型配列(Block, 複数のstmtを持つ)->Ruiさんの実装とは違う．配列にしてみた．
    - 関数の名前
    - Node型(関数の引数(解析後))

- Function型（連結リスト）
    - 次のFunction型
    - 関数の名前
    - LvarList型(params,関数の引数,オフセット指定に使われる,0-6の連結)
    - Node型(node,先頭)
    - LvarList型(locals,ローカル変数)
    - スタックサイズ

- グローバル変数program

# tokenize.nim

- 関数群
    - 10以上の数値生成関数
    - 新しいトークン作成&連結
    - アルファベットチェック
    - アルファベットと数値チェック
    - 予約語チェック

- トークナイズ関数
    - Token型の連結リストの先頭を作成(こいつは無駄になる)
    - inputを左から最後まで読む(ループ)
        - 空白飛ばし
        - 予約語(TkReserved)
        - 識別子(TkIdent)
        - 数値(TkNum)
    - 終端(TkEof)

- Token型連結リストの先頭を返す

# parse.nim

- locals(LvarList，ローカル変数，連結リスト)
- tokPrev(Token, エラー表示用トークン，consumeで進める前のTokenを保持)

- TokenKindチェック関数群
    - consume(記号チェック1)
    - expect(記号チェック2)
    - expectNumber(数値チェック)
    - atEof(終端チェック)
    - consumeIdent(識別子(変数)チェック1)
    - expectIdent(識別子(変数)チェック2)

- 変数生成&チェック関数群
    - findLvar(localsに登録されてるかチェック)
    - pushLvar(localsに追加)

- ノード生成関数群
    - newNode(NodeKind)
    - newNode(NodeKind, Node, Node)
    - newNode(NodeKind, Node)
    - newNode(int)
    - newNode(Lvar)

- 構文解析に必要な関数
    - readFuncParams...読んだ関数の引数をあらかじめlocalsに追加
    - readExprStmt...式の文，codegenでただgen()して，その後popして値を使わないやつ用．（例：node.init, node.inc）
    - funcArgs...関数の引数たちをassign()で解析．解析結果の先頭を返す．

- 再帰下降構文解析(LL1パーサ)
    - program(Function)...Function型のhead作成し，終端までfunction()を生成し繋げ続ける．
    - function(Function)...関数の名前・引数・bodyを読む．bodyは先頭Nodeを作成して，}までstmt()を生成して繋ぎ続ける.
    - stmt(Node)...return, if, while, for, {}, ; ... 文
    - expr(Node)... 式
    - assign(Node)...=
    - equality(Node)... ==, !=
    - relational(Node)...<, <=，>，>=
    - add(Node)...+, -
    - mul(Node)...*, /
    - unary(Node)...+,- primary
    - primary(Node)...(), 変数, 関数，数値

# codegen.nim

- labelSeq(ラベル用数値)

- funcname(最初の関数名前保持，ここではmain)

- argreg(引数用のレジスタ名，６つ，ABIで順番決められてる)

- ローカル変数を扱う関数群
    - genAddr...[rbp-offset]の**アドレス値**を取得，スタックに追加(lea,push), ポインタのデリファレンス経由で変数に値を代入する場合もここで評価（左辺値に何が来るかgenして求める）
    - load...変数をロード
    - store...変数をストア

- gen(NdKindで場合分けて出力)
    - Returnする（NdNum, NdExprStmt, NdLvar, NdAssign, NdAddr, NdDeref, NdIf, NdWhile, NdFor, NdBlock, NdFuncall, NdReturn)
    - gen左辺
    - gen右辺
    - pop rdi
    - pop rax
    - Returnしない，2つのNode結果を使う計算（NdAdd, NdSub, NdMul, NdDiv, NdEq, NdNe, NdL, NdLe）
    - push rax（計算結果はスタックに格納）
    
- codegen(与えられたFunction型の先頭から順番に生成)
    - アセンブリの冒頭
    - Functions型の先頭からなくなるまでループ
        - アセンブリ関数宣言（.global main...）
        - 関数プロローグ
        - レジスタの値をローカル変数のためのスタック上の領域に書き出し（６つ）
        - Node型の先頭からなくなるまでループ
            - gen(node)
        - 関数エピローグ
