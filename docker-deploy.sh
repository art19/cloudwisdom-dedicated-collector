#!/bin/sh

error() {
  echo $1
  exit 1
}

test -z "${VERSION}" && error "VERSION is required"

docker build -t art19/cloudwisdom-dedicated-collector .;
docker tag art19/cloudwisdom-dedicated-collector art19/cloudwisdom-dedicated-collector:$VERSION;
docker push art19/cloudwisdom-dedicated-collector:latest;
docker push art19/cloudwisdom-dedicated-collector:$VERSION;
