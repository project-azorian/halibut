#ARG K8S_VERSION=1.16.0

#RUN K8S_VERSION_ARRAY=( ${K8S_VERSION//./ } ) && echo ${K8S_VERSION_ARRAY[2]}
#ARG CRI=crio

FROM ubuntu:bionic AS oci-runc
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        software-properties-common ;\
    add-apt-repository -y ppa:longsleep/golang-backports ;\
    apt-get update ;\
    apt-get install -y \
        curl \
        git \
        golang-go \
        libseccomp-dev
RUN set -ex ;\
    export GOPATH=/opt/go ;\
    mkdir -p $GOPATH/src/github.com/opencontainers ;\
    git clone https://github.com/opencontainers/runc $GOPATH/src/github.com/opencontainers/runc ;\
    cd $GOPATH/src/github.com/opencontainers/runc ;\
    make static  ;\
    mv -v /opt/go/src/github.com/opencontainers/runc/runc /srv/runc


FROM fedora:latest AS oci-crun-build-base
RUN set -ex ;\
    dnf install -y \
        git \
        dnf-utils \
        gcc \
        meson \
        ninja-build \
        libcap-static \
        make \
        python \
        git \
        gcc \
        automake \
        autoconf \
        libcap-devel \
        systemd-devel \
        yajl-devel \
        libseccomp-devel \
        cmake \
        go-md2man \
        glibc-static \
        python3-libmount \
        libtool \
        diffutils

FROM oci-crun-build-base AS oci-crun-build-systemd
RUN set -ex ;\
    mkdir /out ;\
    yum-builddep -y \
      systemd ;\
    git clone --depth 1 https://github.com/systemd/systemd.git ;\
    mkdir systemd/build ;\
    cd systemd/build ;\
    meson .. --buildtype minsize --strip ;\
    ninja version.h ;\
    ninja libsystemd.a ;\
    cp libsystemd.a /out

FROM oci-crun-build-base AS oci-crun-build-yajl
RUN set -ex ;\
    mkdir /out ;\
    git clone --depth=1 https://github.com/lloyd/yajl.git ;\
    cd yajl ;\
    ./configure LDFLAGS=-static ;\
    cd build ;\
    make -j $(nproc) ;\
    find . -name '*.a' -exec cp \{\} /out \;

FROM oci-crun-build-base AS oci-crun-build-seccomp
RUN set -ex ;\
    mkdir /out ;\
    git clone --depth=1 https://github.com/seccomp/libseccomp.git ;\
    cd libseccomp ;\
    ./autogen.sh ;\
    ./configure --enable-static ;\
    make -j $(nproc) ;\
    find . -name '*.a' -exec cp \{\} /out \;

FROM oci-crun-build-base AS oci-crun
COPY --from=oci-crun-build-systemd /out/* /usr/lib64/
COPY --from=oci-crun-build-yajl /out/* /usr/lib64/
COPY --from=oci-crun-build-seccomp /out/* /usr/lib64/
RUN set -ex ;\
    git clone https://github.com/containers/crun.git /crun ;\
    /crun/contrib/static-builder-x86_64/build.sh ;\
    cp -v /crun/static-build/crun /srv/crun


FROM ubuntu:bionic AS oci-gvisor
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        curl \
        gnupg2 ;\
    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list ;\
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add - ;\
    apt-get update ;\
    apt-get install -y \
        git \
        python3 \
        bazel ;\
    apt-get clean
RUN set -ex ;\
    git clone https://github.com/google/gvisor /opt/gvisor ;\
    cd /opt/gvisor ;\
    bazel build runsc ;\
    cp -v /opt/gvisor/bazel-bin/runsc/linux_amd64_pure_stripped/runsc /srv/runsc


FROM ubuntu:bionic AS cni
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        software-properties-common ;\
    add-apt-repository -y ppa:longsleep/golang-backports ;\
    apt-get update ;\
    apt-get install -y \
        curl \
        git \
        golang-go
RUN set -ex ;\
    export GOPATH=/opt/go ;\
    mkdir -p $GOPATH/src/github.com/containernetworking ;\
    git clone https://github.com/containernetworking/plugins $GOPATH/src/github.com/containernetworking/plugins ;\
    cd $GOPATH/src/github.com/containernetworking/plugins ;\
    git checkout v0.8.1 ;\
    CGO_ENABLED=0 GOARCH=amd64 ./build_linux.sh -ldflags '-extldflags -static -X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=v0.8.1' ;\
    cp -v $GOPATH/src/github.com/containernetworking/plugins/bin/* /srv/


FROM ubuntu:cosmic AS cri-containerd
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        software-properties-common ;\
    add-apt-repository -y ppa:longsleep/golang-backports ;\
    apt-get update ;\
    apt-get install -y \
        curl \
        git \
        golang-go \
        libbtrfs-dev \
        libseccomp-dev
RUN set -ex ;\
    export GOPATH=/opt/go ;\
    mkdir -p $GOPATH/src/github.com/containerd ;\
    git clone https://github.com/containerd/containerd $GOPATH/src/github.com/containerd/containerd ;\
    cd $GOPATH/src/github.com/containerd/containerd ;\
    make EXTRA_FLAGS="-buildmode pie" EXTRA_LDFLAGS='-extldflags "-fno-PIC -static"' BUILDTAGS="netgo osusergo static_build" ;\
    mv -v $GOPATH/src/github.com/containerd/containerd/bin/containerd /srv/containerd


FROM ubuntu:bionic AS cri-crio
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        curl
RUN set -ex ;\
    curl -sSL -o /tmp/crio.tar.gz https://github.com/cri-o/cri-o/releases/download/v1.16.0/crio-v1.16.0.tar.gz ;\
    tar -C /srv -xvf /tmp/crio.tar.gz


FROM ubuntu:bionic AS kubernetes
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        curl
RUN set -ex ;\
    curl -sSL -o /tmp/server.tar.gz https://dl.k8s.io/v1.17.0-rc.1/kubernetes-server-linux-amd64.tar.gz ;\
    tar -C /srv -xvf /tmp/server.tar.gz

FROM ubuntu:bionic AS etcd
RUN set -ex ;\
    apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        software-properties-common ;\
    add-apt-repository -y ppa:longsleep/golang-backports ;\
    apt-get update ;\
    apt-get install -y \
        curl \
        git \
        golang-go
RUN set -ex ;\
    export GOPATH=/opt/go ;\
    mkdir -p $GOPATH/src/github.com/etcd-io ;\
    git clone https://github.com/etcd-io/etcd $GOPATH/src/github.com/etcd-io/etcd ;\
    cd $GOPATH/src/github.com/etcd-io/etcd ;\
    make ;\
    cp -v $GOPATH/src/github.com/etcd-io/etcd/bin/etcd /srv/ ;\
    cp -v $GOPATH/src/github.com/etcd-io/etcd/bin/etcdctl /srv/

FROM scratch AS release
COPY --from=oci-runc /srv/runc /srv/oci-runtimes/runc
COPY --from=oci-crun /srv/crun /srv/oci-runtimes/crun
COPY --from=oci-gvisor /srv/runsc /srv/oci-runtimes/runsc
COPY --from=cni /srv/* /srv/cni/
COPY --from=cri-containerd /srv/containerd /srv/cri/containerd
COPY --from=cri-crio /srv/* /srv/cri/crio/
COPY --from=kubernetes /srv/* /srv/kubernetes/
COPY --from=etcd /srv/* /srv/etcd/

FROM ubuntu:bionic as test
COPY --from=release /srv/* /srv/
