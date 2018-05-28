# Creating a Kubernetes Cluster with 'kubeadm' on existing VMs

Requisites:
- VMs created previously.
- VMs based on Ubuntu 16.04 Xenial.
- VMs with access to `hub.docker.com` and `gcr.io`.
- VMs with access to `deb http://apt.kubernetes.io` and `deb http://*.ubuntu.com/ubuntu`.

## Content
* [1. Preparing VMs](#1-preparing-vms)
* [2. Provision of Kubernetes Cluster](#2-provision-of-kubernetes-cluster)
  * [2.1. Getting access the created Cluster](#21-getting-access-to-created-cluster)
* [3. Access to multiples Kubernetes Clusters](#3-access-to-multiples-kubernetes-clusters)
  * [3.1. Getting access to multiples Kubernetes Clusters from local host](#31-getting-access-to-multiples-kubernetes-clusters)
  * [3.2. Ansible Playbook for getting and merging multiples kubeconfig files](#3.2.-ansible-playbook-for-getting-and-merging-multiples-kubeconfig-files)
* [4. Publishing Services out of Kubernetes Cluster](#4-publishing-services-out-of-kubernetes-cluster)
  * [4.1. Creating a SSH tunnel to forward to a service](#4.1.-creating-a-ssh-tunnel-to-forward-to-a-service)

## 1. Preparing VMs

We need create a set of VMs based on Ubuntu 16.04 Xenial, get their IP addresses and write an `inventory` file required for Ansible.

```bash
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd service-mesh-workshop/labs/00-k8s/kubeadm/infra/vsphere
```

Update `inventory` with the desired hostname and with assigned IP address.
For example, we are going to create a Kubernetes Cluster with 3 VMs (oz1, oz2 and oz3).
```bash
$ vi inventory

[[masters]
oz1  ansible_ssh_host=172.16.70.15  k8s_net_ip_priv=172.16.70.15

[nodes]
oz2  ansible_ssh_host=172.16.70.16  k8s_net_ip_priv=172.16.70.16
oz3  ansible_ssh_host=172.16.70.17  k8s_net_ip_priv=172.16.70.17

[all:vars]
ansible_user=USE_YOUR_VM_SSH_USER
ansible_python_interpreter=/usr/bin/python3
_k8s_version=1.10.2
_k8s_version_deb_min="00"
_proxy_http=http://10.0.11.1:3128
_proxy_https=http://10.0.11.1:3128
_proxy_no=localhost,127.0.0.1
```

Once done, run the `k8scluster_pre_config.yml` Ansible playbook and you will be ready to provision the Cluster with `k8scluster.yml`
```bash
$ ansible-playbook k8scluster_pre_config.yml -k -K
```

## 2. Provision of Kubernetes Cluster

Let's gonna provision the Kubernetes Cluster.
```bash
$ ansible-playbook k8scluster.yml -k -K
```

If everything went well, now you can connect the first Kubernetes master and manage your cluster, in this case is `oz1` with `172.16.70.15` as IP address.
```bash
$ ssh k8sadmin@172.16.70.15
k8sadmin@oz1:~$ kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
oz1       Ready     master    10m       v1.10.2
oz2       Ready     <none>    6m        v1.10.2
oz3       Ready     <none>    6m        v1.10.2

k8sadmin@oz1:~$ kubectl get pod --all-namespaces
NAMESPACE     NAME                          READY     STATUS    RESTARTS   AGE
kube-system   etcd-oz1                      1/1       Running   0          10m
kube-system   kube-apiserver-oz1            1/1       Running   0          9m
kube-system   kube-controller-manager-oz1   1/1       Running   0          10m
kube-system   kube-dns-86f4d74b45-2766j     3/3       Running   0          10m
kube-system   kube-proxy-7wctc              1/1       Running   0          6m
kube-system   kube-proxy-qz6m5              1/1       Running   0          10m
kube-system   kube-proxy-xfnbh              1/1       Running   0          6m
kube-system   kube-scheduler-oz1            1/1       Running   0          9m
kube-system   weave-net-d4vsx               2/2       Running   0          6m
kube-system   weave-net-rzmzf               2/2       Running   0          6m
kube-system   weave-net-tv6f8               2/2       Running   0          9m
```

### 2.1. Getting access to created Cluster

We are going to use the IP address of your first master VM (`oz1` and `172.16.70.15`).
```bash
$ scp k8sadmin@172.16.70.15:/home/k8sadmin/.kube/config ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/server: https:\/\/172.16.70.15:6443/server: https:\/\/oz1:44315/g' ~/.kube/oz1.kubeconfig
```

Create a SSH tunnel to forward the `6443` port of Kubernetes API Server to your local computer.
```bash
$ ssh -nNT -L 44315:localhost:6443 k8sadmin@172.16.70.15
```

Check if standard Kubernetes ports are opened.
```bash
$ nc -zv 172.16.70.15 22
$ nc -zv 127.0.0.1 44315
```

And ready.
```bash
$ export KUBECONFIG=~/.kube/oz1.kubeconfig
$ kubectl get nodes
$ kubectl get pod --all-namespaces
```

Or we can pass the `--kubeconfig` as parameter.
```bash
$ kubectl --kubeconfig ~/.kube/oz1.kubeconfig get nodes
$ kubectl --kubeconfig ~/.kube/oz1.kubeconfig get pod --all-namespaces
```

## 3. Access to multiples Kubernetes Clusters

### 3.1. Getting access to multiples Kubernetes Clusters

From local host, we can merge all `kube config` (e.g. `oz1.kubeconfig` and `rog1.kubeconfig`) files into `~/.kube/config`. Before we have to change some things such as `cluster.name`, `user.name`, `context.name` and remove all `current-context`.
```bash
$ sed -i'.bak' 's/name: kubernetes$/name: oz/g' ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/cluster: kubernetes$/cluster: oz/g' ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/user: kubernetes-admin$/user: oz-admin/g' ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/name: kubernetes-admin@kubernetes$/name: oz-admin@oz/g' ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/name: kubernetes-admin$/name: oz-admin/g' ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/current-context: kubernetes-admin@kubernetes$/#current-context: oz-admin@oz/g' ~/.kube/oz1.kubeconfig

$ sed -i'.bak' 's/name: kubernetes$/name: rog/g' ~/.kube/rog1.kubeconfig
$ sed -i'.bak' 's/cluster: kubernetes$/cluster: rog/g' ~/.kube/rog1.kubeconfig
$ sed -i'.bak' 's/user: kubernetes-admin$/user: rog-admin/g' ~/.kube/rog1.kubeconfig
$ sed -i'.bak' 's/name: kubernetes-admin@kubernetes$/name: rog-admin@rog/g' ~/.kube/rog1.kubeconfig
$ sed -i'.bak' 's/name: kubernetes-admin$/name: rog-admin/g' ~/.kube/rog1.kubeconfig
$ sed -i'.bak' 's/current-context: kubernetes-admin@kubernetes$/#current-context: rog-admin@rog/g' ~/.kube/rog1.kubeconfig
```

We are ready to merge both `kubeconfig` files.
```bash
$ KUBECONFIG=~/.kube/config:~/.kube/oz1.kubeconfig:~/.kube/rog1.kubeconfig kubectl config view --flatten > ~/.kube/merged.kubeconfig
$ mv ~/.kube/config ~/.kube/config.bak && mv ~/.kube/merged.kubeconfig ~/.kube/config
$ unset KUBECONFIG
```

Now, create SSH tunnels to forward the `6443` port of Kubernetes API Server to your local computer.
```bash
$ ssh -nNT -L 44312:localhost:6443 k8sadmin@172.16.70.12
$ ssh -nNT -L 44315:localhost:6443 k8sadmin@172.16.70.15
```

Now, we can select the cluster that we want to manage:
```
$ kubectl config use-context oz-admin@oz
$ kubectl config use-context rog-admin@rog

$ kubectl get nodes
$ kubectl get pod --all-namespaces
```

### 3.2. Ansible Playbook for getting and merging multiples kubeconfig files

If you don't want execute several commands in point `2.1.` and `2.2.`, you can use the `` Ansible Playbook and a new `inventory.kubeconfig` inventory file.
```bash
$ ansible-playbook k8scluster_merge_kubeconfig.yml -k -K -i inventory.kubeconfig
$ KUBECONFIG=~/.kube/config:~/.kube/oz1.kubeconfig:~/.kube/rog1.kubeconfig kubectl config view --flatten > ~/.kube/merged.kubeconfig
$ mv ~/.kube/config ~/.kube/config.bak && mv ~/.kube/merged.kubeconfig ~/.kube/config
$ unset KUBECONFIG

$ ssh -nNT -L 44312:localhost:6443 k8sadmin@172.16.70.12
$ ssh -nNT -L 44315:localhost:6443 k8sadmin@172.16.70.15

$ kubectl config use-context oz-admin@oz
$ kubectl config use-context rog-admin@rog

$ kubectl get nodes
$ kubectl get pod --all-namespaces
```

## 4. Publishing Services out of Kubernetes Cluster

### 4.1. Creating a SSH tunnel to forward to a service

> Bear in mind that creating a SSH tunnel to get access to internal services __is a temporary solution__. We must not open port every time that we want get access a new deployed service.
>
> You should use an Ingress Controller and forward all traffic to an unique exposed port available in the Ingress Controller.
> The Ingress Controller will work as part of a L7 Distributed Firewall.

We are going to install Weave Scope and create a tunnel to forward the traffic to the `30002` port.
```bash
$ kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"
$ kubectl get pod,svc -n weave
$ kubectl -n weave apply -f https://raw.githubusercontent.com/chilcano/ansible-role-weave-scope/master/sample-2-weave-scope-app-svc.yml
$ kubectl get svc/weave-scope-app-svc -n weave -o jsonpath='{.spec.ports[0].nodePort}'
30002
```

Let's create a new SSH tunnel to forward `30015` to `30002` (use `oz1` as hostname for weave scope).
```bash
$ ssh -nNT -L 30015:oz1:30002 k8sadmin@172.16.70.15
$ nc -zv 127.0.0.1 30015
```

Now open Weave Scope (web application) using the `30015` port from your browser.
```bash
$ open http://localhost:30015
```
