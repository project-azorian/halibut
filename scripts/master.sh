#!/bin/bash
set -ex

bash ./install.sh

bash ./snippets/deploy-etcd.sh
bash ./snippets/deploy-kubernetes.sh

bash ./snippets/install-helm.sh

bash ./snippets/deploy-metacontroller.sh
bash ./snippets/deploy-metallb.sh
bash ./snippets/deploy-ingress.sh
bash ./snippets/deploy-dex.sh
bash ./snippets/deploy-argo.sh
bash ./snippets/deploy-rook.sh
bash ./snippets/deploy-lma.sh
