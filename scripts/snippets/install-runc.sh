#!/bin/bash
set -ex

mkdir -p /usr/local/bin
curl -sSL -o /usr/local/bin/runc https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64
chmod +x /usr/local/bin/runc
