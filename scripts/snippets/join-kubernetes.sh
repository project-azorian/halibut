#!/bin/bash
set -ex

MASTER="192.168.60.10"
TOKEN="tkuplq.civsgihd1s6cg94e"
#CERT_HASH="sha256:fa015b89771927a0bae9756be8a27a0a35ec3e80ddadc5a9907d5da990ad303a"

mkdir -p /etc/kubernetes/kubeadm
tee /etc/kubernetes/kubeadm/join.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha3
kind: JoinConfiguration
apiEndpoint:
  advertiseAddress: ${MASTER}
  bindPort: 6443
caCertPath: /etc/kubernetes/pki/ca.crt
discoveryFile: ""
discoveryTimeout: 5m0s
token: ${TOKEN}
tlsBootstrapToken: ${TOKEN}
discoveryToken: ${TOKEN}
discoveryTokenAPIServers:
  - ${MASTER}:6443
discoveryTokenUnsafeSkipCAVerification: true
# discoveryTokenCACertHashes:
#  - ${CERT_HASH}
nodeRegistration:
  criSocket: /var/run/crio/crio.sock
  name: $(hostname)
EOF

until kubeadm join --config /etc/kubernetes/kubeadm/join.yaml; do
  sleep 20
done
