#!/bin/bash
set -ex

cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "macvlan",
      "master": "eth1",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.60.0/24",
        "rangeStart": "192.168.60.100",
        "rangeEnd": "192.168.60.116",
        "routes": [
          { "dst": "0.0.0.0/0" }
        ],
        "gateway": "192.168.60.1"
      }
    }'
EOF
kubectl describe network-attachment-definitions macvlan-conf

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: test-runc
  labels:
    test: runtime-class
spec:
  selector:
    matchLabels:
      name: test-runc
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: macvlan-conf
      labels:
        name: test-runc
        test: runtime-class
    spec:
      runtimeClassName: runc
      containers:
        - name: test
          image: docker.io/busybox:latest
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          env:
            - name: MY_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          command:
            - sh
            - -c
            - |
              while true; do
                { echo -e 'HTTP/1.1 200 OK\r\n'; echo "I am a runc container on \$MY_NODE_NAME"; } | nc -l -p 8080
              done
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: test-kata
  labels:
    test: runtime-class
spec:
  selector:
    matchLabels:
      name: test-kata
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: macvlan-conf
      labels:
        name: test-kata
        test: runtime-class
    spec:
      runtimeClassName: kata
      containers:
        - name: test
          image: docker.io/busybox:latest
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          env:
            - name: MY_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          command:
            - sh
            - -c
            - |
              while true; do
                { echo -e 'HTTP/1.1 200 OK\r\n'; echo "I am a kata container on \$MY_NODE_NAME"; } | nc -l -p 8080
              done
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: test-gvisor
  labels:
    test: runtime-class
spec:
  selector:
    matchLabels:
      name: test-gvisor
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: macvlan-conf
      labels:
        name: test-gvisor
        test: runtime-class
    spec:
      runtimeClassName: gvisor
      containers:
        - name: test
          image: docker.io/busybox:latest
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          env:
            - name: MY_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          command:
            - sh
            - -c
            - |
              while true; do
                { echo -e 'HTTP/1.1 200 OK\r\n'; echo "I am a gvisor container on \$MY_NODE_NAME"; } | nc -l -p 8080
              done
---
apiVersion: v1
kind: Service
metadata:
  labels:
    test: runtime-class
  name: runtime-class-test
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    test: runtime-class
  sessionAffinity: None
  type: ClusterIP
EOF

kubectl wait --for=condition=Ready pod -l test=runtime-class

set +x
COUNTER=0
while [  $COUNTER -lt 100 ]; do
  curl -s "$(dig +short runtime-class-test.default.svc.cluster.local @10.96.0.10)"
  sleep 1
  let COUNTER=COUNTER+1
done
