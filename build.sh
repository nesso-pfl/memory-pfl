#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Building frontend..."
cd frontend
npm run build
cd ..

echo "==> Building backend..."
cd backend
cargo build
cd ..

echo "==> Done"
