#!/bin/bash
set -ex

git clone https://github.com/platform9/etcdadm /opt/etcdadm

podman \
  --cgroup-manager cgroupfs \
  run \
    --rm \
    --net=host \
    -e VERSION_OVERRIDE= \
    -v /opt/etcdadm:/go/src/github.com/platform9/etcdadm \
    -w /go/src/github.com/platform9/etcdadm \
    docker.io/golang:1.10 \
      /bin/bash -exc "make ensure && make"

mv /opt/etcdadm/etcdadm /usr/local/bin/

etcdadm download
