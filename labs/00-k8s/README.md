# Getting a single node Kubernetes Cluster with Minikube

## 1) Create a VM Minikube

```sh
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd $(PWD)/service-mesh-workshop/labs

## start
$ . 00-k8s/k8s-minikube-start.sh kube0

## stop
$ minikube stop

## delete
$ minikube delete
```

## 2) Install extras (Dashboard, Heapster, Weave Scope)

```sh
$ . 00-k8s/k8s-extras-install.sh kube0 latest
```
