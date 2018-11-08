#!/bin/bash
set -ex

mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin

curl -sSL https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz | tar -xvz -C /opt/cni/bin/

modprobe br_netfilter
tee /etc/sysctl.d/k8s.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl --system

rm -rf /etc/cni/net.d/*
tee /etc/cni/net.d/99-loopback.conf <<EOF
{
  "cniVersion": "0.3.1",
  "type": "loopback"
}
EOF
