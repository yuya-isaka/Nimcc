# Nimメモ（コンパイラ作成）

- Nimは一度実行ファイルが生成されると，次回のコンパイルが異様に速い
- strfmtモジュール，fmtで文字列内展開できる
- quit(0)で正常終了
- quit(1)で異常終了
- quit(文字列)で文字列を表示して終了
- os.paramCount()でパラメータの数分かる($os.paramCount())
- os.commandLineParams()[0]でコマンドライン第一引数取得
- os.commandLineParams()，@[]でコマンドライン引数取得
- $で文字列変換
- Pythonとの比較記事わかりやすい
    > https://zenn.dev/dumblepy/articles/3f4f1c288ada66#%E6%96%87%E5%AD%97%E5%88%97
- nim-lang.orgで関数を調べると良い（cのmanみたいな）
- Objectは初期化しないといけない？
    > SIGSEGV: Illegal storage access. (Attempt to read from nil?)って怒られる
- 自己参照のObjectはrefつける？
- let input {.global.} = ... こんな感じでグローバル変数定義できる？
- 参照型のObjectはnewでオブジェクト生成
- 参照型のObjectの代入は，参照渡し
- 整数判定```if input[p].allIt(it.isDigit()):``` 文字列をcharで確認しないといけない
- グローバル変数は関数の外側に定義してたらそれでいい？
- イテレータの挙動は難しい
    > for i in commandLineparams(): @["3+3", "3"] @['3', '+', '3', '3']となる