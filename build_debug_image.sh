#!/bin/bash
# debug ビルド（MRB_DEBUG 有効）のイメージをローカルにだけ作る。push はしない。
#   ./build_debug_image.sh <mruby tag>      例: ./build_debug_image.sh 4.1.0-rc
# 生成物: kishima/mruby:<tag>-debug
# 用途: mrbc --verbose で Prism の AST を出す（MRB_DEBUG → MRC_DEBUG → MRC_DUMP_PRETTY）。
set -eu
TAG="${1:?mruby tag required}"
docker build --platform linux/amd64 \
  -f rake_nobison_install_bookworm_debug.Dockerfile \
  --build-arg MRUBY_VER="$TAG" \
  -t "kishima/mruby:${TAG}-debug" .
