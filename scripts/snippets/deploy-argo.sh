#!/bin/bash
set -ex

curl -sSL -o /usr/local/bin/argo https://github.com/argoproj/argo/releases/download/v2.2.1/argo-linux-amd64
chmod +x /usr/local/bin/argo

kubectl create ns argo
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo/v2.2.1/manifests/install.yaml

#DANGER!
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=default:default

#argo submit --watch https://raw.githubusercontent.com/argoproj/argo/master/examples/hello-world.yaml
#argo submit --watch https://raw.githubusercontent.com/argoproj/argo/master/examples/dag-nested.yaml
