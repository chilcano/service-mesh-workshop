# Creating a Kubernetes Cluster with 'kubeadm' on existing VMs

Requisites:
- VMs based on Ubuntu 16.04 Xenial

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

### 2.1. Getting access from your local computer

We are going to use the IP address of your first master VM (`oz1` and `172.16.70.15`).
```bash
$ scp k8sadmin@172.16.70.15:/home/k8sadmin/.kube/config ~/.kube/oz1.kubeconfig
$ sed -i'.bak' 's/server: https:\/\/172.16.70.15:6443/server: https:\/\/oz1:15443/g' ~/.kube/oz1.kubeconfig
$ export KUBECONFIG=~/.kube/oz1.kubeconfig
```

Create a SSH tunnel to forward the `6443` port of Kubernetes API Server to your local computer.
```bash
$ ssh -nNT -L 44315:localhost:6443 k8sadmin@172.16.70.15
```

And ready.
```bash
$ kubectl get nodes
$ kubectl get pod --all-namespaces
```

Also, we can check if standard Kubernetes ports are opened.
```bash
$ nc -zv 172.16.70.15 22
$ nc -zv 127.0.0.1 44315
```

### 2.2. Creating a new SSH tunnel to forward to any services.

For example, we are going to install Weave Scope and create a tunnel to forward the traffic to the `30002` port.
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
