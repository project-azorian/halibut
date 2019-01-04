#!/bin/bash
set -ex

#NOTE: deploy kubelet reqs
apt-get -y install socat conntrack ipset ipvsadm

mkdir -p /usr/local/bin
for COMPONENT in kubectl kubelet kubeadm; do
  curl -sSL -o /usr/local/bin/${COMPONENT} https://storage.googleapis.com/kubernetes-release/release/v1.13.1/bin/linux/amd64/${COMPONENT}
  chmod +x /usr/local/bin/${COMPONENT}
done

mkdir -p \
  /var/lib/kubelet \
  /var/lib/kubernetes \
  /var/run/kubernetes


echo "KUBELET_EXTRA_ARGS=--feature-gates=RuntimeClass=true --cgroup-driver=cgroupfs --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock --image-pull-progress-deadline=15m --network-plugin=cni" > /etc/default/kubelet

tee /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/home/

[Service]
EnvironmentFile=-/etc/default/kubelet
ExecStartPre=-/sbin/swapoff --all
ExecStartPre=-/sbin/modprobe \
                ip_vs \
                ip_vs_rr \
                ip_vs_wrr \
                ip_vs_sh \
                nf_conntrack_ipv4
ExecStart=/usr/local/bin/kubelet \$KUBELET_EXTRA_ARGS
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/systemd/system/kubelet.service.d
tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/local/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet
