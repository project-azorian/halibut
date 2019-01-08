#!/bin/bash
set -ex

PACKAGES="libmnl-1.0.3 libnfnetlink-1.0.1 libnetfilter_cttimeout-1.0.0 libnetfilter_cthelper-1.0.0 libnetfilter_queue-1.0.2 libnetfilter_conntrack-1.0.4"
CONNTRACK=conntrack-tools-1.4.2

rm -rf $PACKAGES $CONNTRACK

apt-get update && apt-get install -y curl make pkg-config gcc flex bison

fetch() {
    curl -sSL http://www.netfilter.org/projects/${1%-*}/files/$1.tar.bz2 | tar xj
}

for PACKAGE in $PACKAGES; do
    fetch $PACKAGE
    (cd $PACKAGE; ./configure && make LDFLAGS=-static install)
done

fetch $CONNTRACK
(cd $CONNTRACK; ./configure && make LDFLAGS=-static && rm -f src/conntrack && make LDFLAGS=-all-static)
cp $CONNTRACK/src/conntrack .
