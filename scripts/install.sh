#!/bin/bash
set -ex

bash ./snippets/install-docker.sh


bash ./snippets/install-crictl.sh
bash ./snippets/install-kata.sh
bash ./snippets/install-runc.sh
bash ./snippets/install-gvisor.sh
bash ./snippets/install-crio.sh

bash ./snippets/install-podman.sh

bash ./snippets/install-cni.sh

bash ./snippets/install-etcd.sh
bash ./snippets/install-kubernetes.sh
