#!/bin/sh

git pull
docker buildx build --no-cache --platform linux/amd64,linux/arm64,linux/arm/v7 -t ampache/ampache:nosql-develop -t ampache/ampache:nosql-preview --push .
