#!/bin/bash
MEMORY=${1:? memory}
DISK=${2:? disk}
cd "$(dirname $0)"
KEYPUB="$(cat $HOME/.ssh/id_ecdsa.pub)"
# the passwd is the first 16 chars of the sha256sum of the private key
# encoded with md5sum to put in the configuration file
PASSWD="$(cat $HOME/.ssh/id_ecdsa | sha256sum | head -c 16)"
mkdir -p /var/kvm/my_k8s_cluster
virsh net-create network.xml
for i in 0 1 2 3
do
    if test "$i" = "0"
    then HOST="master"
    else HOST="node$i"
    fi
    bash preseed.sh $i $HOST "$PASSWD" "$KEYPUB"
    bash node.sh $i $HOST $MEMORY $DISK
done
