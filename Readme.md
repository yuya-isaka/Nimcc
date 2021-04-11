# NimでCコンパイラ作るぞ（自分用メモ）
> 参考：https://github.com/rui314/9cc
***
## 開発環境構築（Dockerで構築）
(要らなかったかも，一旦ローカルで開発を進める...4/11)
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
    $ docker run --rm -v $HOME/nimcc:/nimcc -w /9cc compilerbooknim make test

    コンテナをインタラクティブに仕様
    $ docker run --rm -it -v $HOME/nimcc:/nimcc compilerbooknim
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

***

## Dockerのエイリアス作成
(Docker関連要らなかったかもだから，一旦保留)

***

## 初めの第一歩
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


## メモ
- NimMemo.md
- CompilerMemo.md
- CSMemo

## 最初の言語
    5+20-4
- 最初に数字が一つ
- その後に0個以上の「項」が続いている
- 「項」というのは+の後に数字が来ているものか，-の後に数字が来ているものか