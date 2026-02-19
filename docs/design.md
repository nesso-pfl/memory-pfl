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

Docker イメージは GitHub Actions で自動ビルドされ、ghcr.io にプッシュされる。

### CI/CD

main ブランチへの push 時に `.github/workflows/release.yml` が実行される:

1. Docker イメージをビルド
2. `ghcr.io/nesso-pfl/memory-pfl:latest` および `:sha` タグでプッシュ

### 前提

- PostgreSQL + pgvector が稼働していること
- Redis が稼働していること（認証セッション管理用）
- Keycloak 等の OIDC プロバイダが設定済みであること

### 実行

```
docker pull ghcr.io/nesso-pfl/memory-pfl:latest

docker run -d \
  --env-file .env \
  -p 1230:1230 \
  ghcr.io/nesso-pfl/memory-pfl:latest
```

### 環境変数

`.env.example` を参照。

| 変数 | 必須 | 説明 |
|------|------|------|
| `DATABASE_URL` | Yes | PostgreSQL 接続 URL |
| `GEMINI_API_KEY` | Yes | Google AI Studio の API キー |
| `PORT` | Yes | 待ち受けポート |
| `AUTH_ISSUER_URL` | Yes | OIDC Issuer URL |
| `AUTH_CLIENT_ID` | Yes | OIDC Client ID |
| `AUTH_CLIENT_SECRET` | Yes | OIDC Client Secret |
| `AUTH_REDIRECT_URI` | Yes | 認証コールバック URL |
| `AUTH_POST_LOGIN_URI` | Yes | ログイン後リダイレクト先 |
| `AUTH_POST_LOGOUT_URI` | Yes | ログアウト後リダイレクト先 |
| `AUTH_REDIS_URL` | Yes | Redis 接続 URL |

### ローカルビルド

```
GITHUB_TOKEN=ghp_xxx just build-image
```
