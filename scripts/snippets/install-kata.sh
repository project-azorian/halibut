#!/bin/bash
set -ex

rmmod kvm-intel
sh -c "echo 'options kvm-intel nested=y' >> /etc/modprobe.d/kvm.conf"
modprobe kvm-intel

# https://github.com/kata-containers/documentation/commit/808d85b46793dc45a28b78ec5f3482e58b50da72
BRANCH="stable-1.4"
ARCH=$(arch)
RELEASE=$(lsb_release -rs)
echo "deb http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${BRANCH}/xUbuntu_${RELEASE}/ /" > /etc/apt/sources.list.d/kata-containers.list
curl -sSL "http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${BRANCH}/xUbuntu_${RELEASE}/Release.key" | sudo apt-key add -
apt-get update
apt-get -y install kata-runtime kata-proxy kata-shim
kata-runtime kata-check
