#!/bin/bash
set -ex

PACKAGES="libmnl-1.0.4"
IPSET=ipset-6.34

rm -rf $PACKAGES $CONNTRACK

apt-get update && apt-get install -y curl make pkg-config gcc flex bison linux-headers-$(uname -r)

fetch() {
    curl -sSL http://www.netfilter.org/projects/${1%-*}/files/$1.tar.bz2 | tar xj
}

for PACKAGE in $PACKAGES; do
    fetch $PACKAGE
    (cd $PACKAGE; ./configure --enable-static --disable-shared && make LDFLAGS=-static install)
done

curl -sSL http://ipset.netfilter.org/${IPSET}.tar.bz2 | tar xj

(cd ${IPSET}; ./configure --enable-static --disable-shared && make LDFLAGS=-static)
cp ${IPSET}/src/ipset .
