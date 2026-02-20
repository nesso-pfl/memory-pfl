#!/bin/sh
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
