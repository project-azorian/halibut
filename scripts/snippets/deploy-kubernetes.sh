#!/bin/bash
set -ex

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
mkdir -p /etc/kubernetes/pki
tee /etc/kubernetes/pki/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

mkdir -p /etc/kubernetes/kubeadm
. /etc/etcd/etcd.env
tee /etc/kubernetes/kubeadm/create.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
clusterName: kubernetes
kubernetesVersion: v1.13.1
imageRepository: k8s.gcr.io
networking:
  dnsDomain: cluster.local
  podSubnet: 172.18.0.0/16
  serviceSubnet: 10.96.0.0/12
etcd:
  external:
    endpoints:
      - "${ETCD_ADVERTISE_CLIENT_URLS}"
    caFile: "/etc/etcd/pki/ca.crt"
    certFile: "/etc/etcd/pki/apiserver-etcd-client.crt"
    keyFile: "/etc/etcd/pki/apiserver-etcd-client.key"
apiServerExtraArgs:
  feature-gates: RuntimeClass=true
  experimental-encryption-provider-config: "/etc/kubernetes/pki/encryption-config.yaml"
  oidc-issuer-url: https://dex.dex.svc.cluster.local:30001
  oidc-client-id: my-cluster
  oidc-ca-file: "/etc/kubernetes/pki/ca.crt"
  oidc-username-claim: name
  oidc-username-prefix: 'oidc:'
  oidc-groups-claim: groups
  oidc-groups-prefix: 'oidc:'
---
apiVersion: kubeadm.k8s.io/v1alpha3
kind: InitConfiguration
bootstrapTokens:
  - groups:
      - system:bootstrappers:kubeadm:default-node-token
    token: tkuplq.civsgihd1s6cg94e
    ttl: 24h0m0s
    usages:
      - signing
      - authentication
nodeRegistration:
  criSocket: /var/run/crio/crio.sock
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
EOF

kubeadm config images pull --config /etc/kubernetes/kubeadm/create.yaml
crictl images

echo "192.168.60.10 dex.dex.svc.cluster.local dex-k8s-authenticator.dex.svc.cluster.local kubernetes.default.svc.cluster.local" >> /etc/hosts
kubeadm init --config /etc/kubernetes/kubeadm/create.yaml --ignore-preflight-errors RequiredIPVSKernelModulesAvailable

mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"

kubectl taint nodes --all node-role.kubernetes.io/master-

bash ./snippets/deploy-cni-multus.sh

kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/runtimeclass/runtimeclass_crd.yaml
cat <<EOF | kubectl apply -f -
kind: RuntimeClass
apiVersion: node.k8s.io/v1alpha1
metadata:
  name: runc
spec:
  runtimeHandler: runc
---
kind: RuntimeClass
apiVersion: node.k8s.io/v1alpha1
metadata:
  name: kata
spec:
  runtimeHandler: kata
---
kind: RuntimeClass
apiVersion: node.k8s.io/v1alpha1
metadata:
  name: gvisor
spec:
  runtimeHandler: gvisor
EOF

kubectl wait --timeout=120s --for=condition=Ready nodes/$(hostname)

until kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers -o name | grep -q "^pod/coredns"; do
  sleep 5
done
kubectl wait --timeout=480s --for=condition=Ready pods -n kube-system -l k8s-app=kube-dns
