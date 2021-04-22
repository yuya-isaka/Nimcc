# nimcc: A small C compiler written in Nim

## Prerequisites
- 64-bit Linux environment

- Having [nim](https://nim-lang.org/), gcc, make, git, binutils and libc6-dev installed.

    ```
    $ sudo apt install -y nim gcc make git binutils libc6-dev
    ```
- Setting up a Linux development environment using Docker
    ```
    Open the directory containing the Dockerfile and type

    $ docker build -t compilerbooknim .
    $ docker run --rm -it -v $HOME/nimcc:/home/user/nimcc compilerbooknim
    ```
- (MacOS is quite compatible with Linux at the source level of assembly, but not fully compatible.)

## How to run
- Open the directory and type ```make``` in the terminal.

## Features
- Basic arithmetic operations
- Unary plus and unary minus
- Comparison operations
- Functions
- Local variables
- Control syntax (if, while, for)
- Compound statement (Block)

## Reference
- https://github.com/rui314/9cc
- https://www.sigbus.info/compilerbook

***

## Memorandom

- 64ビットのLinux環境を想定
- 現状，アセンブリをmain → _main と書き換えてmacで動作してる（のでmacで開発中，詰まったらDockerのLinux環境にお引っ越し．．）
- 詰まったので，アセンブリを _main -> main に書き戻してお引っ越し

### 開発環境構築（Dockerで構築）
- (要らなかったかも，一旦ローカルで開発を進める...4/11)
- 要りました！ x86-64のmovzb命令がmacだと使えなかった．．詳しく調べてないけど，Dockerで開発
> 参考：https://www.sigbus.info/compilerbook#docker

#### ソースコード編集やGit操作など，プラットフォームに依存しない通常の開発作業はDockerの外で行い，ビルドやテストのコマンドのみDockerの中で実行する構成
1. Dockerfile準備
2. Dockerイメージ作成（名前：compilerbooknim）
    ```
    イメージ作成
    $ docker build -t compilerbooknim .

    イメージ一覧
    $ docker images
    ```
3. Dockerコンテナ使い方
    ```
    コンテナ作成&コマンド実行(コマンド終了次第,コンテナも破棄)
    $ docker run --rm compilerbooknim ls /

    コンテナを使ったビルド
    $ docker run --rm -v $HOME/nimcc:/home/user/nimcc -w /9cc compilerbooknim make test

    コンテナをインタラクティブに仕様
    $ docker run --rm -it -v $HOME/nimcc:/home/user/nimcc compilerbooknim
    ```
4. *コンテナ/イメージに新たなアプリケーションを追加

    ```
    例：curlコマンドをインストール

    コンテナ作成
    $ docker run -it compilerbooknim
    $ sudo apt update
    $ sudo apt install -y curl
    $ exit

    サスペンド状態のコンテナ確認
    $ docker container ls -a

    コンテナをイメージに書き戻す
    $ docker commit [CONTAINER ID] compilerbooknim

    サスペンド状態のコンテナ削除
    $ docker system prune
    ```

### Dockerのエイリアス作成
(Docker関連要らなかったかもだから，一旦保留)
つくらんかも


### 初めの第一歩
> 参考：https://www.sigbus.info/compilerbook#%E3%82%B9%E3%83%86%E3%83%83%E3%83%971%E6%95%B4%E6%95%B01%E5%80%8B%E3%82%92%E3%82%B3%E3%83%B3%E3%83%91%E3%82%A4%E3%83%AB%E3%81%99%E3%82%8B%E8%A8%80%E8%AA%9E%E3%81%AE%E4%BD%9C%E6%88%90
1. nimcc.nim を準備

    - コマンドライン引数を一つ受け取り，アセンブリに変換（とても簡単な処理）
    ```
    コンパイルして実行ファイルを作成
    $ nim c -r nimcc.nim 123

    アセンブリファイルを生成
    $ ./nimcc 123 > tmp.s

    アセンブル（macOSだと出来ない, _mainにすると実行できた．）
    $ cc -o tmp tmp.s
    $ ./tmp
    $ echo $?
    ```

    - _mainにする必要がある
2. 自動テストの作成

    - test.sh作成
    ```
    実行権限を付与
    chmod a+x test.sh
    ```

    - test.sh内でnimコンパイル&アセンブルを実行

3. Makefile作成

    - make か make test でテスト実行
    - make clean で綺麗


### メモ
- nimMemo.md
- nimMemo2.md
- compilerMemo.md
- csMemo


### Nim，外部モジュール
- OS
- strutils
- strformat


### 電卓に毛が生えた処理系を作ろう
### 1. 整数一個をコンパイルする処理系
### 2. 単純な加減算できる処理系
    5+20-4
- 最初に数字が一つ
- その後に0個以上の「項」が続いている
- 「項」というのは+の後に数字が来ているものか，-の後に数字が来ているものか

### 3. トークナイザの導入
- 空白文字に対応
- 文字列をトークン列に分割
    > トークンを分類して型をつけられる
- コンパイラ実装のつ行状，トークン列の終わりを表す特殊な型をひとつ定義しておくとプログラムが簡潔になる
- C言語では，トークンはポインタで繋いだ連結リストになるように設計
- 入力文字列の扱いをNim用に設計
- 現状，トークンはポインタ（先頭アドレス）で保持せず，charのseq型とインデックスで管理（もっとエレガントに書けるはず．．．）
- 配列外参照で怒られることが多かった（入力文字列を配列で管理している代償）

### 4. エラーメッセージの改良
- C言語はポインタを利用して，入力の何バイト目でエラーが起きたかを把握して出力
- Nimでは，トークン型に入力文字列の先頭インデックス用の属性を追加
    > Token.at
- 初期化されていない参照型のオブジェクトはnilとなるので，そのチェックを入れている
    > 本来はOption型でnull安全に実装すべき．．．

### 5. 四則演算完成

### 6. 単項プラス，単項マイナス

### 7. 比較演算子

### 分割コンパイル

### 8. 1文字のローカル変数

### 9. 複数文字のローカル変数

### 10. return文

## License
Copyright 2021 Yuya Isaka under the terms of the MIT license
found at http://www.opensource.org/licenses/mit-license.html