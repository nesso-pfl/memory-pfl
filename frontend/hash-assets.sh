#!/bin/sh
# ビルド成果物のファイル名に content hash を埋め込む。
# app.js → app.a1b2c3d4.js のようにリネームし、index.html の参照も書き換える。
# ファイル内容が変わればハッシュも変わるため、ブラウザキャッシュの破棄を
# ファイル名の変更で自然に行える (cache busting)。
# サーバー側では「ドットが2つ以上 = ハッシュ付き」と判定し immutable キャッシュを返す。
set -eu
cd "$(dirname "$0")/dist"

for file in app.js styles.css; do
  hash=$(sha256sum "$file" | cut -c1-8)
  name="${file%.*}"
  ext="${file##*.}"
  hashed="${name}.${hash}.${ext}"
  mv "$file" "$hashed"
  sed -i "s|${file}|${hashed}|" index.html
done
