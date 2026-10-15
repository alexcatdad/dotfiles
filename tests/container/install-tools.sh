#!/bin/sh
set -eu
test "$(uname -m)" = aarch64
cd /tmp
curl -fsSL --retry 3 https://github.com/atuinsh/atuin/releases/download/v18.23.0/atuin-aarch64-unknown-linux-gnu.tar.gz -o atuin.tar.gz
echo '21869faff1fedb9f8fb27837136567b089bcd588d21252533d5b314605517ae2  atuin.tar.gz' | sha256sum -c -
tar xzf atuin.tar.gz
install -m 755 atuin-aarch64-unknown-linux-gnu/atuin /usr/local/bin/atuin
curl -fsSL --retry 3 https://github.com/starship/starship/releases/download/v1.26.0/starship-aarch64-unknown-linux-musl.tar.gz -o starship.tar.gz
echo 'dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b  starship.tar.gz' | sha256sum -c -
tar xzf starship.tar.gz
install -m 755 starship /usr/local/bin/starship
curl -fsSL --retry 3 https://github.com/oven-sh/bun/releases/download/bun-v1.4.2/bun-linux-aarch64.zip -o bun.zip
echo '54328bbc2d9c8e0c9f892c544d66c57a83b84139e34909e5ee81758f1ac8fda7  bun.zip' | sha256sum -c -
unzip -q bun.zip
install -m 755 bun-linux-aarch64/bun /usr/local/bin/bun
rm -rf /tmp/atuin* /tmp/starship* /tmp/bun*
