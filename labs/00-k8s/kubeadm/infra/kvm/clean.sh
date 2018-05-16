HOST=${1:?hostname}
virsh destroy $HOST
virsh undefine $HOST
rm /var/kvm/my_k8s_cluster/$HOST/image.qcow2
