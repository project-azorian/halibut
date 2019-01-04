#!/bin/bash
set -ex

mkdir -p /usr/local/bin
curl -sSL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.13.0/crictl-v1.13.0-linux-amd64.tar.gz | tar -xvz -C /usr/local/bin/

tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///var/run/crio/crio.sock
EOF
