# デプロイ

Docker イメージは GitHub Actions で自動ビルドされ、VPS に転送・起動される。

## CI/CD

main ブランチへの push 時に `.github/workflows/deploy.yml` が実行される:

1. Docker イメージをビルド
2. SSH 経由で `docker save | gzip | docker load` で VPS に転送
3. VPS で `docker compose up -d memory-pfl`

### GitHub Actions の設定

**Secrets:**

| 名前 | 説明 |
|------|------|
| `GH_PAT` | GitHub PAT（auth-pfl の取得用、`Contents: Read-only`） |
| `SSH_PRIVATE_KEY` | VPS 接続用の SSH 秘密鍵 |
| `VPS_HOST` | VPS のホスト |
| `VPS_USER` | VPS の SSH ユーザー名 |

**Variables:**

| 名前 | 説明 |
|------|------|
| `DEPLOY_PATH` | VPS 上の compose.yaml があるディレクトリ |

## VPS の前提

- Docker + Docker Compose がインストール済み
- `DEPLOY_PATH` に compose.yaml があり、`memory-pfl` サービスが定義されている
- PostgreSQL + pgvector が稼働していること
- Redis が稼働していること（認証セッション管理用）
- Keycloak 等の OIDC プロバイダが設定済みであること

## 環境変数

VPS 上の `.env` に設定する。`.env.example` を参照。

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

## ローカルビルド

```
GITHUB_TOKEN=ghp_xxx just build-image
```
