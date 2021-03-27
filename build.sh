#!/bin/sh

git pull
docker buildx build --no-cache --platform linux/amd64,linux/arm64,linux/arm/v7 -t ampache/ampache:develop -t ampache/ampache:preview --push .
