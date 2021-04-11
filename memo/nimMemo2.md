# Nimメモ（普段）

- 簡素でエレガントな構文
- ネイティブバイナリを吐く（Cにトランスコンパイル）
- Nimはキャメルケース好み
- ヒープにアロケートされるオブジェクトが少なくなるよう意識した設計（できるだけGC管轄にならんように）
- echoは改行付きの出力
- constはコンパイル時に計算
- 多数の入力例：
    ```
    let input = stdin.readLine.split.map(parseInt)
    ```
- コレクションにはitems，pairsが生えている->iterator．（省略可能？）
- 関数で副作用だけ欲しい時は明示的にdiscard
- 演算子も全て関数，バッククォートで囲むとユーザ定義できる
- イテレータと関数の名前空間は別
- enum，勝手に番号振られる（0origin）
- varargs，可変長引数
- 単純なマクロはテンプレートで書ける
    ```
    template `!=` (a,b: untyped): untyped =
        not (a == b)
    ```
- マクロは抽象構文木を分析・操作
- 二次元動的配列を楽に生成テンプレート
    ```
    template newMatrix(len: int, init: untyped): untyped =
        var result = newSeq[type(init)](len)
        for i in 0..<len:
            result[i] = init
        result

    大きさ20x10の二次元動的配列を生成
    var seq2D = newMatrix(20, newSeq[bool](10))
    ```