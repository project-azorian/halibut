#!/bin/bash
set -ex

mkdir -p /usr/local/bin
curl -sSL -o /usr/local/bin/runsc https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17
chmod +x /usr/local/bin/runsc
