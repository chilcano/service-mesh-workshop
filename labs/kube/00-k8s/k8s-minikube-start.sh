#!/usr/bin/env bash

VM_NAME=${1:-kube0}
MINIKUBE_MEMORY=${2:-4096}    # 2048 if you dont want to use istio
MINIKUBE_ISO_URL=${3:-file:///Users/Chilcano/Downloads/__kube_repo/minikube-v0.25.1.iso}

minikube start \
--vm-driver=virtualbox \
--profile ${VM_NAME} \
--kubernetes-version v1.8.0 \
--extra-config apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota" \
--cpus 4 \
--memory ${MINIKUBE_MEMORY} \
--iso-url ${MINIKUBE_ISO_URL}

echo "----------- checking status -----------"

# login & post checking:
minikube profile ${VM_NAME}
kubectl config use-context ${VM_NAME}

# status
minikube status
kubectl cluster-info
kubectl get nodes
