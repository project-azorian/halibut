#!/bin/bash
set -ex

apt-get update
apt-get install -y docker.io

docker run --rm --net=host -v /:/mnt/rootfs:rw --read-only docker.io/port/halibut:latest
