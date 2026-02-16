# 開発メモ

## bun run で spago のビルドが失敗する

### 現象

`bun run build` で `Failed to find purs` エラーが出る。

### 原因

`bun run` は package.json scripts 内の `npx` を `bun x` に自動変換する。
`bun x spago` は spago が内部で呼ぶ `purs` バイナリを解決できない。

加えて、asdf 経由でグローバルインストールされた `purs` が壊れており、
PATH を明示的に設定しても spago 独自のバイナリ解決で壊れた方が優先される。

### 回避策

`npm run build` を使う。`npx` は Node のモジュール解決でローカルの `purs` を正しく見つける。

```sh
# NG
bun run build

# OK
npm run build
```
