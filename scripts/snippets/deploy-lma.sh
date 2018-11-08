#!/bin/bash
set -ex

git clone https://github.com/wilkers-steve/skinny-lma /opt/skinny-lma

kubectl create ns monitoring
for MANIFEST in $(ls /opt/skinny-lma/*.yaml); do
  cat ${MANIFEST} | kubectl apply -f -
done
