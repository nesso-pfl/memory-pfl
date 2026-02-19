# デプロイ

Docker イメージは GitHub Actions で自動ビルドされ、ghcr.io にプッシュされる。

## CI/CD

main ブランチへの push 時に `.github/workflows/release.yml` が実行される:

1. Docker イメージをビルド
2. `ghcr.io/nesso-pfl/memory-pfl:latest` および `:sha` タグでプッシュ

## 前提

- PostgreSQL + pgvector が稼働していること
- Redis が稼働していること（認証セッション管理用）
- Keycloak 等の OIDC プロバイダが設定済みであること

## 実行

```
docker pull ghcr.io/nesso-pfl/memory-pfl:latest

docker run -d \
  --env-file .env \
  -p 1230:1230 \
  ghcr.io/nesso-pfl/memory-pfl:latest
```

## 環境変数

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

## ローカルビルド

```
GITHUB_TOKEN=ghp_xxx just build-image
```
