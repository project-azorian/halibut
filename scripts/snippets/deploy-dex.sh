#!/bin/bash

CFSSLURL=https://pkg.cfssl.org/R1.2
for CFSSL_BIN in cfssl cfssljson; do
  if ! type -p "${CFSSL_BIN}"; then
    sudo curl -sSL -o "/usr/local/bin/${CFSSL_BIN}" "${CFSSLURL}/${CFSSL_BIN}_linux-amd64"
    sudo chmod +x "/usr/local/bin/${CFSSL_BIN}"
    ls "/usr/local/bin/${CFSSL_BIN}"
  fi
done

tee /tmp/dex-csr.json <<EOF
{
    "CN": "dex.dex.svc.cluster.local",
    "hosts": [
        "dex.dex.svc.cluster.local"
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "US",
            "L": "CA",
            "ST": "San Francisco"
        }
    ]
}
EOF
cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key  -profile=server /tmp/dex-csr.json | cfssljson -bare server

kubectl create ns dex
kubectl create -n dex secret tls dex-tls --cert=./server.pem --key=./server-key.pem

git clone https://github.com/intlabs/dex-k8s-authenticator.git /opt/dex-k8s-authenticator
cd /opt/dex-k8s-authenticator

helm template --namespace dex --name dex charts/dex | kubectl apply -n dex -f -

tee /tmp/ca.yaml <<EOF
caCerts:
  enabled: true
  secrets:
  - name: ca-cert1
    filename: ca1.crt
    value: $(cat /etc/kubernetes/pki/ca.crt | base64 -w 0)
EOF

helm template --namespace dex --name dex-k8s-authenticator charts/dex-k8s-authenticator --values=/tmp/ca.yaml | kubectl apply -n dex -f -

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: oidc:admins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: "oidc:admin"
  - apiGroup: rbac.authorization.k8s.io
    kind: Group
    name: "oidc:admins"
EOF


mkdir -p ${HOME}/.kube/certs/my-cluster/
cat /etc/kubernetes/pki/ca.crt > ${HOME}/.kube/certs/my-cluster/k8s-ca.crt


#kubectl config use-context kubernetes-admin@kubernetes
