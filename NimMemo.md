# Nimメモ

- 簡素でエレガントな構文
- Nimは一度実行ファイルが生成されると，次回のコンパイルが異様に速い
- strfmtモジュール，fmtで文字列内展開できる
- quit(0)で正常終了
- quit(1)で異常終了
- quit(文字列)で文字列を表示して終了
- os.paramCount()でパラメータの数分かる($os.paramCount())
- os.commandLineParams()[0]でコマンドライン第一引数取得
- os.commandLineParams()，@[]でコマンドライン引数取得
- $で文字列変換
- Nimはキャメルケース好み
- Pythonとの比較記事わかりやすい
    > https://zenn.dev/dumblepy/articles/3f4f1c288ada66#%E6%96%87%E5%AD%97%E5%88%97
- nim-lang.orgで関数を調べると良い（cのmanみたいな）
- GCはCycle Collector
- Objectはスタック領域確保
- ref Object はヒープ領域確保（自動で開放）
- 関数の引数は基本は値渡し（値が変更されたら自動で参照渡し）
- 関数の引数でvarをつけると参照渡し？
- @[]はseq型のエイリアス
- 関数は第一引数のメソッドとして扱える（シンタックスシュガー）
    > 既にある型にメソッド追加可能，糖衣構文
- 型エイリアス，既存の型に別名つけられる