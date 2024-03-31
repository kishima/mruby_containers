#!/bin/bash

set -e

echo "* building Docker image *"
echo "docker hub registry: $1"
echo "docker file: $2"
echo "tag: $3"
echo "version: $4"

docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

docker buildx build -f $2 --platform linux/amd64,linux/arm64 -t $1:$3 --build-arg MRUBY_VER=$4 . --push

docker buildx rm mybuilder
