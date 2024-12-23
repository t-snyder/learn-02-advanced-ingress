#!/bin/bash

# Load image to minikube when built
eval $(minikube docker-env)

WORKDIR=/media/tim/ExtraDrive1/Projects/learn-02-advanced-ingress
PAPAYA_DIR=/media/tim/ExtraDrive1/Projects/learn-02-advanced-ingress/papaya

cd $WORKDIR/docker

cp -r $PAPAYA_DIR/target/lib/  ./lib
cp    $PAPAYA_DIR/target/PapayaServer.jar ./PapayaServer.jar

docker build -t library/papaya:1.0 -f PapayaDockerFile .

rm PapayaServer.jar
rm -rf lib

cd ../scripts
