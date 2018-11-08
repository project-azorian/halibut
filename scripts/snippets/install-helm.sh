#!/bin/bash

HELM_VERSION="v2.11.0"
TMP_DIR=$(mktemp -d)
curl -sSL "https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -zxv --strip-components=1 -C "${TMP_DIR}"
mv "${TMP_DIR}/helm" "${TMP_DIR}/tiller" /usr/local/bin/
rm -rf "${TMP_DIR}"

tee /etc/systemd/system/helm-tiller.service <<EOF
[Unit]
Description=Helm Tiller
After=network.target

[Service]
User=root
Restart=always
ExecStart=/usr/local/bin/tiller -listen 127.0.0.1:44134

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now helm-tiller

echo 'export HELM_HOST=127.0.0.1:44134' >> ~/.bashrc
helm init --client-only --skip-refresh
