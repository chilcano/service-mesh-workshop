# Creating a Kubernetes Cluster with 'kubeadm' and Vagrant

These Ansible Playbooks can be used for creating a Kubernetes Cluster on any Virtualization Provider (Vagrant/VirtualBox, VMWare vSphere, KVM, etc.) by following the 'kubeadm' approach (https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm).

## 0. Requisites

In order to create a Kubernetes Cluster, you have to create a set of VMs, for the moment you have to create them using Ubuntu Xenial, with access to the Debian repository `http://apt.kubernetes.io`.
This repository contains a `Vagrantfile` to create 3 VMs with Ubuntu to start quickly.

Previously you need:
- to create VirtualBox VMs
  - Hashicorp Vagrant
  - VirtualBox
- to create the Kubernetes Cluster
  - Ansible

## 1. Create the VMs

```
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd service-mesh-workshop/labs/00-k8s/kubeadm/infra/virtualbox
$ vagrant up
```

Useful commands:
```
$ vagrant status
$ vagrant destroy
$ vagrant halt
$ vagrant reload
```

## 2. Fixing Vagrant issues

Issue:
```
/opt/vagrant/embedded/gems/2.1.0/gems/vagrant-2.1.0/lib/vagrant/util/safe_chdir.rb:25:in `chdir': Too many open files - getcwd (Errno::EMFILE)
```

Workaround:
```
$ vagrant destroy
$ cd $TMPDIR
$ rm -rf vagrant-*
```

## 3. Copy vagrant ssh config

```
$ rm -rf ~/.ssh/config
$ vagrant ssh-config >> ~/.ssh/config
```

## 4. Ansible provision to create the Kubernetes Cluster

Update your `/etc/hosts` file of your local computer and `inventory` file accordingly to your `Vagrantfile`.
Also update `inventory` file with the Kubernetes' version that you want install.
```bash
$ apt-cache policy kubeadm

1.10.4-00 500
   500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
1.10.3-00 500
   500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
1.10.2-00 500
   500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
1.10.1-00 500
   500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
*** 1.10.0-00 500
   500 http://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
   100 /var/lib/dpkg/status
...

$ apt-cache policy docker.io
docker.io:
  Installed: 1.13.1-0ubuntu1~16.04.2
  Candidate: 1.13.1-0ubuntu1~16.04.2
  Version table:
 *** 1.13.1-0ubuntu1~16.04.2 500
        500 http://archive.ubuntu.com/ubuntu xenial-updates/universe amd64 Packages
        100 /var/lib/dpkg/status
     1.10.3-0ubuntu6 500
        500 http://archive.ubuntu.com/ubuntu xenial/universe amd64 Packages

$ sudo apt-cache madison docker.io
 docker.io | 1.13.1-0ubuntu1~16.04.2 | http://archive.ubuntu.com/ubuntu xenial-updates/universe amd64 Packages
 docker.io | 1.10.3-0ubuntu6 | http://archive.ubuntu.com/ubuntu xenial/universe amd64 Packages
 docker.io | 1.10.3-0ubuntu6 | http://archive.ubuntu.com/ubuntu xenial/universe Sources
 docker.io | 1.13.1-0ubuntu1~16.04.2 | http://archive.ubuntu.com/ubuntu xenial-updates/universe Sources
```

And to check what version was installed, to use this:
```bash
$ sudo dpkg -l kubeadm
$ sudo dpkg -l docker.io
```

```bash
$ sudo nano /etc/hosts

127.0.0.1 master1 node1 node2

$ nano inventory

[masters]
master1   k8s_net_ip_priv=10.0.0.10

[nodes]
node1     k8s_net_ip_priv=10.0.0.11
node2     k8s_net_ip_priv=10.0.0.12

[all:vars]
ansible_user=vagrant
ansible_python_interpreter=/usr/bin/python3
_k8s_version=1.10.2
_k8s_version_deb_min="00"

## proxy
#_proxy_http=http://10.0.11.1:3128
#_proxy_https=http://10.0.11.1:3128
#_proxy_no=localhost,127.0.0.1

## set static ip address
#_inet_dev_name=ens160
#_inet_dev_network=172.16.70.0
#_inet_dev_netmask=255.255.255.0
#_inet_dev_gateway=172.16.70.254
#_inet_dev_dns1=10.0.10.1

## k8s master used to announce
_k8s_master_hostname=master1
```

Check is created VMs are reachable:
```
$ ansible all -i inventory -m ping

k8s-ubu-3 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
k8s-ubu-1 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
k8s-ubu-2 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
```

Run the `k8scluster.yml` Ansible Playbook:
```
$ ansible-playbook -i inventory k8scluster.yml
```

## 5. Checking the Kubernetes Cluster

```
$ vagrant status
Current machine states:

master1               running (virtualbox)
node1                 running (virtualbox)
node2                 running (virtualbox)

$ vagrant ssh master1 -- kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
master1   Ready     master    5m        v1.10.2
node1     Ready     <none>    4m        v1.10.2
node2     Ready     <none>    4m        v1.10.2

$ vagrant ssh master1 -- kubectl get pod --all-namespaces
$ vagrant ssh master1 -- kubectl get pod,svc -n kube-system
$ vagrant ssh master1 -- kubectl get pod,svc -n weave
```

Checking installed Kubernetes version:
```
$ vagrant ssh master1 -- dpkg -l kubeadm
$ vagrant ssh master1 -- dpkg -l kubelet
$ vagrant ssh master1 -- dpkg -l kubectl
```

Or:
```
$ vagrant ssh master1 -- apt list kubeadm
$ vagrant ssh master1 -- apt list kubelet
$ vagrant ssh master1 -- apt list kubectl
```

Checking available Kubernetes versions:
```
$ vagrant ssh master1 -- apt-cache policy kubeadm
$ vagrant ssh master1 -- apt-cache policy kubelet
$ vagrant ssh master1 -- apt-cache policy kubectl
```

## 6. Getting access the Cluster from `kubectl`

```bash
$ scp vagrant@master1:/home/vagrant/.kube/config master1.kubeconfig
$ sed -i'.bak' 's/server: https:\/\/10.0.0.10:6443/server: https:\/\/master1:6443/g' master1.kubeconfig
$ export KUBECONFIG=$PWD/master1.kubeconfig
```

Update local `/etc/hosts` file with:
```bash
$ sudo nano /etc/hosts

127.0.0.1 master1
```

Now, you can connect to remote Kubernetes Cluster:
```bash
$ kubectl get nodes
```

## 7. Installing Weave Scope

```bash
$ kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"
$ kubectl get pod,svc -n weave
```

Above will create by default a ClusterIP, which we couldn't reach it. For that we have to deploy a NodePort Service and open the specified port. In this sample is `30002` port.
```bash
$ kubectl -n weave apply -f https://raw.githubusercontent.com/chilcano/ansible-role-weave-scope/master/sample-2-weave-scope-app-svc.yml
$ kubectl get svc/weave-scope-app-svc -n weave -o jsonpath='{.spec.ports[0].nodePort}'
30002
```

Now open Weave Scope webapp using the `30002` port.
```bash
$ open http://master1:$(kubectl get svc/weave-scope-app-svc -n weave -o jsonpath='{.spec.ports[0].nodePort}')
```

## 7. Deploying and testing Lab 01-delivering-on-k8s

```bash
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/01-delivering-on-k8s/hello-app.yaml
$ kubectl get pod -n hello
```

To call `hello-v1` and `hello-v2` services, we have to know how the incomming traffic flows or routes to the services `hello-v1` and `hello-v2`.
```bash
$ kubectl get svc -n hello -o wide
NAME                           READY     STATUS    RESTARTS   AGE       IP          NODE
po/hello-v1-d9b64698c-5zkp9    1/1       Running   0          17h       10.46.0.0   node1
po/hello-v2-7464c8d7b5-drsj8   1/1       Running   0          17h       10.40.0.1   node2

NAME                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE       SELECTOR
svc/hello-svc-cip   ClusterIP      10.105.237.40    <none>        5010/TCP         17h       app=hello
svc/hello-svc-lb    LoadBalancer   10.105.247.136   <pending>     5020:30304/TCP   17h       app=hello
svc/hello-svc-np    NodePort       10.96.246.166    <none>        5030:31014/TCP   17h       app=hello
```

This shows us that we do have 3 ways to call `hello-v1` and `hello-v2`, each service is listening in different ports (5010, 5020 and 5030) and different IP addresses, that doesn't mean that `hello-v1` and `hello-v2` are accesible from outside (public network). A ClusterIP Service is available internally, a LoadBalancer would be available from outside if the Edge Proxy in the K8s Cluster was configured properly. Finally, a NodePort Service is available internally in the node only.

In other words, we have to get access to K8s Cluster before calling the services.
We have 3 options to do that:
- Option 1: Remote access to any Node or VM and call the services by using their IP addresses: `vagrant ssh <VM> -- <command>`
- Option 2: Remote access to current Pod hosting `hello-v1` or `hello-v2`, and call the services by using their service names: `kubectl exec <pod> -- <command>`
- Option 3: Install a specialized Pod in different namespace, get remote access to it and perform `curl` to call the services: `kubectl exec <pod> -- <command>`

### 7.1. Option 1

Calling `hello-v1` and `hello-v2` through `hello-svc-cip`.
```bash
$ vagrant ssh master1 -- curl -s http://10.105.237.40:5010/hello
Hello version: v1, instance: hello-v1-d9b64698c-5zkp9
Hello version: v2, instance: hello-v2-7464c8d7b5-drsj8
```

### 7.2. Option 2

Accessing to `hello-v1` pod (`po/hello-v1-d9b64698c-5zkp9`) and calling `hello-v1` and `hello-v2` through `hello-svc-cip`.
```bash
$ kubectl exec hello-v1-d9b64698c-5zkp9 -n hello -- curl -s http://hello-svc-cip:5010/hello
Hello version: v1, instance: hello-v1-d9b64698c-5zkp9
Hello version: v2, instance: hello-v2-7464c8d7b5-drsj8
```

### 7.3. Option 3

Accessing to `hello-v1` pod (`po/hello-v1-d9b64698c-5zkp9`) and calling `hello-v1` and `hello-v2` through `hello-svc-cip` by using other pod in different namespace.

Deploying Kali Linux (security audit tools)
```bash
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/05-security-assessment/kali-linux.yaml
$ export KALI_POD_NAME=$(kubectl get pod -l run=kali-linux -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec -ti ${KALI_POD_NAME} -- /bin/sh
# apt update -y
# apt install -y nmap curl netcat
```

Calling `hello-v1` and `hello-v2`  from `KALI_POD_NAME`. We have to use the `fqdn` for `hello-svc-cip`, it is `hello-svc-cip.hello.svc.cluster.local`.
```bash
# curl -s http://hello-svc-cip.hello.svc.cluster.local:5010/hello
Hello version: v1, instance: hello-v1-d9b64698c-5zkp9
Hello version: v2, instance: hello-v2-7464c8d7b5-drsj8
```

## 8. Working with Ingress Controller

Instead of getting and managing IP addresses and Ports when we want call a service, we can use and manage this kind of routes by using Ingress Controller and Ingress Resources. Then, let's install Istio Ingress Controller following the lab `02-ingress`.
Generally the Ingress Controllers listen on standard ports like http/80 and https/443. The EdgeProxy in the K8s Cluster should open the `80` and `443`ports.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/istio-0.6.0/install/kubernetes/components/istio-ns.yaml
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/istio-0.6.0/install/kubernetes/components/istio-config-updated.yaml
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/istio-0.6.0/install/kubernetes/components/istio-rbac-beta.yaml
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/istio-0.6.0/install/kubernetes/components/istio-pilot.yaml
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/istio-0.6.0/install/kubernetes/components/istio-ingress-updated.yaml
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/istio-0.6.0/install/kubernetes/components/istio-ingress-svc.yaml
```
Checking Ingress and Pilot.
```bash
$ kubectl get deploy,po,svc -n istio-system -o wide
$ kubectl logs -l istio=pilot -n istio-system -c discovery
$ kubectl logs -l istio=pilot -n istio-system -c istio-proxy
$ kubectl logs -l istio=ingress -n istio-system
```

Redeploying previous `hello-v1` and `hello-v2` services and adding Ingress Resources (routes).
```bash
$ kubectl delete ns hello
$ kubectl apply -f https://raw.githubusercontent.com/chilcano/service-mesh-workshop/master/labs/02-ingress/hello-with-ingress.yaml
$ kubectl get pod,svc,ing -n hello
NAME                           READY     STATUS    RESTARTS   AGE
po/hello-v1-d9b64698c-swd97    1/1       Running   1          2h
po/hello-v2-7464c8d7b5-ccnch   1/1       Running   1          2h

NAME               TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
svc/hello-svc-np   NodePort   10.107.104.216   <none>        5030:31081/TCP   2h

NAME            HOSTS     ADDRESS   PORTS     AGE
ing/hello-ing   *                   80        2h
```

Calling `hello-v1` and `hello-v2` through the `ing/hello-ing` Ingress Resource and `svc/istio-ingress-svc`.
The `svc/istio-ingress-svc` is a new Svc definition where I'm assigning a specific ports, because these ports should be opened in the EdgeProxy.
```bash
$ kubectl get svc -l istio=ingress -n istio-system -o wide
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE       SELECTOR
istio-ingress       LoadBalancer   10.100.250.176   <pending>     80:30421/TCP,443:32543/TCP   2h        istio=ingress
istio-ingress-svc   NodePort       10.106.78.107    <none>        80:30080/TCP,443:30443/TCP   15m       istio=ingress

$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress-svc -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s http://master1:${ISTIO_INGRESS_PORT}/hello
Hello version: v2, instance: hello-v2-54f5878c79-v5znq
Hello version: v1, instance: hello-v1-d9b64698c-swd97
```

## 9. Working with Sidecars

```bash
TBC
```
