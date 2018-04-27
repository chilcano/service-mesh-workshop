#!/usr/bin/env bash

VM_NAME=${1:-kube0}
MINIKUBE_MEMORY=${2:-4096}    # 2048 if you dont want to use istio
MINIKUBE_ISO_URL=${3:-file:///Users/Chilcano/Downloads/__kube_repo/minikube-v0.25.1.iso}

minikube start \
--vm-driver=virtualbox \
--profile ${VM_NAME} \
--kubernetes-version v1.8.0 \
--extra-config apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota" \
--extra-config apiserver.Authorization.Mode=RBAC \
--bootstrapper localkube \
--network-plugin cni \
--feature-gates CustomResourceValidation=true \
--cpus 4 \
--memory ${MINIKUBE_MEMORY} \
--iso-url ${MINIKUBE_ISO_URL}

echo "----------- checking status -----------"

# login & post checking:
minikube profile ${VM_NAME}
kubectl config use-context ${VM_NAME}

# Fixes CrashLoopBackOff for kube-dns pod and RBAC enabled
# - https://github.com/kubernetes/minikube/issues/2302
# - https://github.com/kubernetes/kubernetes/issues/50799
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

# status
minikube status
kubectl cluster-info
kubectl get nodes
