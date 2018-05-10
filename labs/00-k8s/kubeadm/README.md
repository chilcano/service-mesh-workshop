# Creating a Kubernetes Cluster with 'kubeadm'

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

## 3. Copy ssh config to host

```
$ rm -rf ~/.ssh/config
$ vagrant ssh-config >>~/.ssh/config
```

Update your `hosts` file accordingly to your `Vagrantfile`:
```
$ sudo nano /etc/hosts

127.0.0.1 master1 node1 node2
```

## 4. Ansible provision to create the Kubernetes Cluster

Update your `inventory` file accordingly to your `Vagrantfile`, once done run the `k8scluster.yml` Ansible Playbook:
```
$ ansible-playbook k8scluster.yml
```

## 5. Checking the Kubernetes Cluster

```
$ cd infra/virtualbox
$ vagrant status
Current machine states:

master1               running (virtualbox)
node1                 running (virtualbox)
node2                 running (virtualbox)

$ vagrant ssh master1 -- kubectl get nodes
$ vagrant ssh master1 -- kubectl get pod --all-namespaces
$ vagrant ssh master1 -- kubectl get pod,svc -n kube-system
$ vagrant ssh master1 -- kubectl get pod,svc -n weave
```

## 6. Getting access the Cluster from `kubectl`

```
$ scp vagrant@master1:/home/vagrant/.kube/config master1.config
$ export KUBECONFIG=~/1github-repo/service-mesh-workshop/labs/00-k8s/kubeadm/infra/virtualbox/master1.config
```

## 7. Installing Weave Scope

```
$ kubectl -n weave apply -f https://raw.githubusercontent.com/chilcano/ansible-role-weave-scope/master/sample-2-weave-scope-app-svc.yml
$ kubectl get svc/weave-scope-app-svc -n weave -o jsonpath='{.spec.ports[0].nodePort}'
3002

Now open the 3002 port in your Kubernetes Master.

$ open http://master1:$(kubectl get svc/weave-scope-app-svc -n weave -o jsonpath='{.spec.ports[0].nodePort}')
```
