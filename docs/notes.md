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

## ベクトル検索 (SQLite)

sqlite-vec を採用。

- SQLite 拡張 (C のみ、軽量)。単一バイナリに静的リンク可能
- インデックスが DB 内に保存される → バックアップ・トランザクション整合性が自動
- 現状ブルートフォース検索。個人用途 (数万件) なら 384 次元で数十 ms
- ANN (IVF) サポートは開発中
- Rust: 公式 crate `sqlite-vec` あり。sqlx との統合は `sqlite3_auto_extension` を unsafe で呼ぶ workaround が必要

```rust
// sqlx との統合方法
unsafe {
    libsqlite3_sys::sqlite3_auto_extension(Some(std::mem::transmute(
        sqlite_vec::sqlite3_vec_init as *const (),
    )));
}
```

参考:
- https://github.com/asg017/sqlite-vec
- https://github.com/launchbadge/sqlx/issues/3147 (sqlx 統合の workaround)

### 不採用にしたもの

- **sqlite-vss**: 開発終了、sqlite-vec に移行済み
- **USearch**: C++ 依存、インデックスが DB 外部ファイル
- **Hora**: メンテナンス停止 (2021年で止まっている)
- **vectorlite**: Rust crate なし、C++ 依存

## Embedding API

Gemini embedding-001 を採用。

- 日本語品質: MTEB Multilingual リーダーボード1位
- 次元数: 3072 (768 に truncate 可能、Matryoshka 学習済み)
- 無料枠: 100 RPM, 1,000 RPD (入力トークン課金なし)
- 有料: $0.15 / 1M tokens
- Rust からは reqwest で REST API を直接呼ぶ

注意: 2025年12月に Google が無料枠を 50-80% 削減した前例あり。

### 不採用にしたもの

- **OpenAI text-embedding-3-small**: 日本語品質が Gemini に劣る。async-openai crate は成熟しているのでフォールバック候補
- **Ollama (ローカル)**: 日本語品質が弱い
- **Cohere embed-v3**: OpenAI より割高、Rust SDK なし
- **BGE-M3**: 品質は高いが Rust 単一バイナリ構成と相性が悪い
