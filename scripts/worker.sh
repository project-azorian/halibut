#!/bin/bash
set -ex

bash ./install.sh

bash ./snippets/join-kubernetes.sh
