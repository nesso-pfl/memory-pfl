#!/bin/sh
# ビルド成果物のファイル名に content hash を埋め込み assets/ に配置する。
# app.js → assets/app.a1b2c3d4.js のようにリネームし、index.html の参照も書き換える。
# ファイル内容が変わればハッシュも変わるため、ブラウザキャッシュの破棄を
# ファイル名の変更で自然に行える (cache busting)。
# サーバー側では assets/ 配下を immutable キャッシュとして返す。
set -eu
cd "$(dirname "$0")/dist"

mkdir -p assets

for file in app.js styles.css; do
  hash=$(sha256sum "$file" | cut -c1-8)
  name="${file%.*}"
  ext="${file##*.}"
  hashed="assets/${name}.${hash}.${ext}"
  mv "$file" "$hashed"
  sed -i "s|${file}|${hashed}|" index.html
done
