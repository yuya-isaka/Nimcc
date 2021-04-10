# NimでCコンパイラ作るぞ（自分用メモ）
> 参考：https://github.com/rui314/9cc
***
## 開発環境構築（Dockerで構築）
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