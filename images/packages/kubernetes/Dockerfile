FROM alpine:latest as socat-builder
RUN apk --update add build-base bash automake git curl linux-headers
SHELL [ "/bin/bash", "-cex" ]
RUN mkdir /build
RUN mkdir /output
COPY socat.sh /build/socat.sh
RUN bash /build/socat.sh

FROM docker.io/ubuntu:bionic as ipset-builder
SHELL [ "/bin/bash", "-cex" ]
COPY ipset.sh /usr/local/bin/ipset.sh
RUN bash /usr/local/bin/ipset.sh

FROM docker.io/ubuntu:bionic as conntrack-builder
SHELL [ "/bin/bash", "-cex" ]
COPY conntrack.sh /usr/local/bin/conntrack.sh
RUN bash /usr/local/bin/conntrack.sh

FROM scratch as staging
ARG K8S_VERSION=v1.13.1
COPY --from=ipset-builder /ipset /usr/local/bin/
COPY --from=conntrack-builder /conntrack /usr/local/bin/
ADD https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl /usr/local/bin/
ADD https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubelet /usr/local/bin/
ADD https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubeadm /usr/local/bin/

FROM scratch
COPY --from=staging / /
CMD true

# Build: docker build --network=host ./images/packages/kubernetes -t docker.io/port/kubernetes:latest
# Push: docker push docker.io/port/kubernetes:latest
# Use: TEMP=$(mktemp -d); docker pull docker.io/port/kubernetes:latest && docker save docker.io/port/kubernetes:latest | undocker --output ${TEMP} && cp -ravf ${TEMP}/* / && rm -rf ${TEMP}
