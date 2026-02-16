# memory-pfl 設計

## 概要

日々思ったあらゆる事柄を記憶・検索するためのシステム。

## アーキテクチャ

```
Frontend (PureScript / Halogen, PWA)
    ↓ REST API
Backend (Rust / Axum)
    ↓
SQLite + Embedding Index
    ↑
MCP Server (読み取り専用)
    ↑
外部サービス
```

## ストレージ

- **SQLite** をメインデータベースとして採用
- **Embedding index** によりセマンティック検索を実現
- 将来的に **pgvector** への移行を検討

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

- 作成画面
- 更新画面
- 削除画面
- 検索画面

### 検索 UI

タブ UI で開発メモリ/一般メモリの検索を切り替え可能にする。

### PWA

PWA として実装する。理由:

- 単一バイナリ配信を想定 (バックエンドにフロントエンドアセットを埋め込み)
- スマホからのアクセスの快適性
