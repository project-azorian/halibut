#!/bin/bash
set -ex

time docker run \
  --rm \
  --net=host \
  --pid=host \
  --ipc=host \
  --privileged \
  --volume /sys:/sys:rw \
  --volume /run:/run:rw \
  --volume /:/mnt/rootfs:rw \
  --volume $(pwd)/../ansible/podman.yaml:/srv/ansible/playbook.yaml:ro \
  docker.io/port/halibut:latest

podman info
