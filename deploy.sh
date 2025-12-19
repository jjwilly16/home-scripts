#!/bin/bash

VERSION="1.0.1"
REGISTRY=192.168.1.54:5000

docker build -t home-scripts .
docker tag home-scripts $REGISTRY/home-scripts:$VERSION
docker push $REGISTRY/home-scripts:$VERSION
