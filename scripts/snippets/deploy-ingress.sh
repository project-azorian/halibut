#!/bin/bash
set -ex

cat <<EOF | kubectl apply -f -
---
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: v1
data:
  # see https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md for all possible options and their description
  map-hash-bucket-size: "128"
  hsts: "false"
kind: ConfigMap
metadata:
  name: nginx-load-balancer-conf
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-services
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: udp-services
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
---
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-http-backend
  namespace: kube-system
  labels:
    app.kubernetes.io/name: default-http-backend
    app.kubernetes.io/part-of: kube-system
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: default-http-backend
      addonmanager.kubernetes.io/mode: Reconcile
  template:
    metadata:
      labels:
        app.kubernetes.io/name: default-http-backend
        addonmanager.kubernetes.io/mode: Reconcile
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-http-backend
        # Any image is permissible as long as:
        # 1. It serves a 404 page at /
        # 2. It serves 200 on a /healthz endpoint
        image: gcr.io/google_containers/defaultbackend:1.4
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 20m
            memory: 30Mi
          requests:
            cpu: 20m
            memory: 30Mi
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: kube-system
  labels:
    app.kubernetes.io/name: nginx-ingress-controller
    app.kubernetes.io/part-of: kube-system
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: nginx-ingress-controller
      app.kubernetes.io/part-of: kube-system
      addonmanager.kubernetes.io/mode: Reconcile
  template:
    metadata:
      labels:
        app.kubernetes.io/name: nginx-ingress-controller
        app.kubernetes.io/part-of: kube-system
        addonmanager.kubernetes.io/mode: Reconcile
      annotations:
        prometheus.io/port: '10254'
        prometheus.io/scrape: 'true'
    spec:
      serviceAccountName: nginx-ingress
      terminationGracePeriodSeconds: 60
      containers:
      - image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.19.0
        name: nginx-ingress-controller
        imagePullPolicy: IfNotPresent
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          timeoutSeconds: 1
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        ports:
        - containerPort: 80
          hostPort: 80
        - containerPort: 443
          hostPort: 443
        # (Optional) we expose 18080 to access nginx stats in url /nginx-status
        - containerPort: 18080
          hostPort: 18080
        args:
        - /nginx-ingress-controller
        - --default-backend-service=\$(POD_NAMESPACE)/default-http-backend
        - --configmap=\$(POD_NAMESPACE)/nginx-load-balancer-conf
        - --tcp-services-configmap=\$(POD_NAMESPACE)/tcp-services
        - --udp-services-configmap=\$(POD_NAMESPACE)/udp-services
        - --annotations-prefix=nginx.ingress.kubernetes.io
        # use minikube IP address in ingress status field
        - --report-node-internal-ip-address
        securityContext:
          capabilities:
              drop:
              - ALL
              add:
              - NET_BIND_SERVICE
          # www-data -> 33
          runAsUser: 33
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: Reconcile

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: system:nginx-ingress
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - nodes
  - pods
  - secrets
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - "extensions"
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
- apiGroups:
  - "extensions"
  resources:
  - ingresses/status
  verbs:
  - update

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: system::nginx-ingress-role
  namespace: kube-system
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - pods
  - secrets
  - namespaces
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - configmaps
  resourceNames:
  # Defaults to "<election-id>-<ingress-class>"
  # Here: "<ingress-controller-leader>-<nginx>"
  # This has to be adapted if you change either parameter
  # when launching the nginx-ingress-controller.
  - ingress-controller-leader-nginx
  verbs:
  - get
  - update
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - get

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: system::nginx-ingress-role-binding
  namespace: kube-system
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: EnsureExists
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: system::nginx-ingress-role
subjects:
- kind: ServiceAccount
  name: nginx-ingress
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:nginx-ingress
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: EnsureExists
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:nginx-ingress
subjects:
- kind: ServiceAccount
  name: nginx-ingress
  namespace: kube-system
---
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: v1
kind: Service
metadata:
  name: default-http-backend
  namespace: kube-system
  labels:
    app.kubernetes.io/name: default-http-backend
    app.kubernetes.io/part-of: kube-system
    kubernetes.io/minikube-addons: ingress
    kubernetes.io/minikube-addons-endpoint: ingress
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app.kubernetes.io/name: default-http-backend
EOF