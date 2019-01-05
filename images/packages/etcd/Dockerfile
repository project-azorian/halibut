FROM docker.io/golang:1.10 as builder
SHELL [ "/bin/bash", "-cex" ]
WORKDIR /go/src/github.com/platform9/etcdadm
RUN git clone https://github.com/platform9/etcdadm /go/src/github.com/platform9/etcdadm
RUN make ensure
RUN make

FROM scratch as staging
ARG ETCD_VERSION=v3.3.8
COPY --from=builder /go/src/github.com/platform9/etcdadm/etcdadm /usr/local/bin/
ADD https://github.com/coreos/etcd/releases/download/$ETCD_VERSION/etcd-$ETCD_VERSION-linux-amd64.tar.gz /var/cache/etcdadm/etcd/$ETCD_VERSION/etcd-$ETCD_VERSION-linux-amd64.tar.gz

FROM scratch
ARG ETCD_VERSION=v3.3.8
COPY --from=staging / /
CMD true

# Build: docker build --network=host ./images/packages/etcd -t docker.io/port/etcdadm:latest
# Push: docker push port/etcdadm:latest
# Use: docker pull docker.io/port/etcdadm:latest && docker save docker.io/port/etcdadm:latest | undocker --output /
