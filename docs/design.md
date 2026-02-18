# memory-pfl 設計

## 概要

日々思ったあらゆる事柄を記憶・検索するためのシステム。

## アーキテクチャ

```
Frontend (PureScript / Halogen, PWA)
    ↓ REST API
Backend (Rust / Axum)
    ↓
PostgreSQL + pgvector
    ↑
MCP Server (読み取り専用)
    ↑
外部サービス
```

## ストレージ

- **PostgreSQL + pgvector** をメインデータベースとして採用
- **pgvector** によりセマンティック検索を実現（詳細: [semantic-search.md](semantic-search.md)）

## メモリモデル

メモリは以下の2種類に分類される:

- **開発メモリ**: 開発に関する記憶
- **一般メモリ**: それ以外の記憶

分類には **タグ** を使用する。

## Backend (Rust / Axum)

REST API でメモリの CRUD を提供:

- Create: メモリの作成
- Read: メモリの取得・検索
- Update: メモリの更新
- Delete: メモリの削除

## MCP Server

外部サービスから memory-pfl のデータを取得するためのインターフェース。
**読み取り専用** (取得のみサポート)。

## Frontend (PureScript / Halogen)

### 画面構成

単一画面構成。検索画面をメインとし、作成・更新はモーダルで対応する。

- **検索画面** (メイン画面)
  - タブ UI で開発メモリ/一般メモリを切り替え
  - 検索バー + 結果一覧
  - 結果の各行に編集・削除操作
  - 新規作成ボタン
- **作成/更新モーダル**
  - 内容・タグ・カテゴリの入力フォーム
  - 作成と更新で共用

### PWA

PWA として実装する。理由:

- 単一バイナリ配信を想定 (バックエンドにフロントエンドアセットを埋め込み)
- スマホからのアクセスの快適性

## デプロイ

Docker で単一イメージとしてデプロイする。

### ビルド

```
just build-image
```

### 実行

```
docker run -d \
  --env-file .env \
  -p 1230:1230 \
  memory-pfl
```

### 環境変数

`.env.example` を参照。

| 変数 | 必須 | 説明 |
|------|------|------|
| `DATABASE_URL` | Yes | PostgreSQL 接続 URL |
| `GEMINI_API_KEY` | Yes | Google AI Studio の API キー |
| `PORT` | Yes | 待ち受けポート |
