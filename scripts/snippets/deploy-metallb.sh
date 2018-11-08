#!/bin/bash
set -ex

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml
curl -sSL https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/example-layer2-config.yaml | \
  sed 's|192.168.1.240/28|192.168.60.240/28|g' | kubectl create -f -
