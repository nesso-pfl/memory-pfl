#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Building frontend..."
cd frontend
PATH="$PWD/node_modules/.bin:$PATH"
npx spago bundle --bundle-type app --outfile dist/app.js
cp static/index.html dist/
cd ..

echo "==> Building backend..."
cd backend
cargo build
cd ..

echo "==> Done"
