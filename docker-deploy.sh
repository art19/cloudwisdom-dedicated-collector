#!/bin/sh

error() {
  echo $1
  exit 1
}

test -z "${VERSION}"         && error "VERSION is required"
test -z "${DOCKER_USERNAME}" && error "DOCKER_USERNAME is required"
test -z "${DOCKER_PASSWORD}" && error "DOCKER_PASSWORD is required"

docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD";
docker build -t art19/cloudwisdom-dedicated-collector .;
docker tag art19/cloudwisdom-dedicated-collector art19/cloudwisdom-dedicated-collector:$VERSION;
docker push art19/cloudwisdom-dedicated-collector:latest;
docker push art19/cloudwisdom-dedicated-collector:$VERSION;
