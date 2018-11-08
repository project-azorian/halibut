#!/bin/bash
set -ex

add-apt-repository -y ppa:projectatomic/ppa
apt-get update
apt-get install -y podman

rm -f /etc/cni/net.d/87-podman-bridge.conflist
mkdir -p /etc/containers
curl -sSLo /etc/containers/registries.conf \
  https://raw.githubusercontent.com/projectatomic/registries/master/registries.conf

podman info
