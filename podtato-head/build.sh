#!/usr/bin/env bash

REPOSITORY="yogeek2"

TAG="0.1.0"

docker build -f ./DockerfileV"${TAG}" . --tag "${REPOSITORY}"/podtatohead:v"${TAG}"

TAG="0.1.1"

docker build -f ./DockerfileV"${TAG}" . --tag "${REPOSITORY}"/podtatohead:v"${TAG}"

TAG="0.1.2"

docker build -f ./DockerfileV"${TAG}" . --tag "${REPOSITORY}"/podtatohead:v"${TAG}"