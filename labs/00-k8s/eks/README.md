# AWS EKS

## 1. Install Kubernetes Cli, Heptio AWS Authenticator and Weave AWS EKS Cli

The AWS EKS provides version 1.10 of Kubernetes and needs `kubectl` version `1.10.3`. Then, let's install or update `kubectl`.
```sh
$ brew install kubectl
$ brew update kubectl
$ brew upgrade kubectl
$ kubectl version --short --client
Client Version: v1.10.5
```

Install Heptio AWS Authenticator (this is for Mac OSX).
```sh
$ curl -o heptio-authenticator-aws https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/darwin/amd64/heptio-authenticator-aws
$ chmod +x ./heptio-authenticator-aws; sudo mv ./heptio-authenticator-aws /usr/local/bin
```

More info:
- https://kubernetes.io/docs/tasks/tools/install-kubectl
- https://docs.aws.amazon.com/eks/latest/userguide/configure-kubectl.html

Install `eksctl`.
```sh
$ curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
$ sudo mv /tmp/eksctl /usr/local/bin
```

## 2. Create an AWS EKS Cluster

The AWS Cli is not required, but sometimes it's needed to work directly with AWS API. To install it execute the next commands:
```sh
$ brew install awscli
$ brew update awscli
$ brew upgrade awscli
$ aws --version
aws-cli/1.15.40 Python/3.7.0 Darwin/17.6.0 botocore/1.10.40
```

### 2.1. Prepare AWS credentials

Create `~/.aws/credentials` file and fill out properly.

```sh
$ nano ~/.aws/credentials

[default]
aws_access_key_id = YOUR-AWS-ACCESS-KEY-ID-DEFAULT
aws_secret_access_key = your-aws-secret-access-key-default

[eks-usr-roger]
aws_access_key_id = YOUR-AWS-ACCESS-KEY-ID
aws_secret_access_key = your-aws-secret-access-key
```

Create `~/.aws/config` file and fill out properly.
```sh
$ nano ~/.aws/config

[default]
region = eu-west-2
output = json

[profile eks-usr-roger]
region = us-east-1
output = json
```

### 2.2. Generate SSH keys

```sh
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/Chilcano/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/Chilcano/.ssh/id_rsa.
Your public key has been saved in /Users/Chilcano/.ssh/id_rsa.pub.
[...]
```

Copy the content of `/Users/Chilcano/.ssh/id_rsa.pub` into `AWS > IAM > Users > Security credentials > Upload SSH public key`.

### 2.3. Create a Cluster

```sh
$ eksctl create cluster --cluster-name kube-rog-3 --nodes 3 --profile eks-usr-roger

2018-07-02T11:08:35+01:00 [ℹ]  importing SSH public key "/Users/Chilcano/.ssh/id_rsa.pub" as "EKS-kube-rog-3"
2018-07-02T11:08:36+01:00 [ℹ]  creating EKS cluster "kube-rog-3" in "us-west-2" region
2018-07-02T11:08:36+01:00 [ℹ]  creating ServiceRole stack "EKS-kube-rog-3-ServiceRole"
2018-07-02T11:08:36+01:00 [ℹ]  creating VPC stack "EKS-kube-rog-3-VPC"
2018-07-02T11:09:18+01:00 [✔]  created ServiceRole stack "EKS-kube-rog-3-ServiceRole"
2018-07-02T11:09:37+01:00 [✔]  created VPC stack "EKS-kube-rog-3-VPC"
2018-07-02T11:09:37+01:00 [ℹ]  creating control plane "kube-rog-3"
2018-07-02T11:20:00+01:00 [✔]  created control plane "kube-rog-3"
2018-07-02T11:20:00+01:00 [ℹ]  creating DefaultNodeGroup stack "EKS-kube-rog-3-DefaultNodeGroup"
2018-07-02T11:23:43+01:00 [✔]  created DefaultNodeGroup stack "EKS-kube-rog-3-DefaultNodeGroup"
2018-07-02T11:23:43+01:00 [✔]  all EKS cluster "kube-rog-3" resources has been created
2018-07-02T11:23:43+01:00 [ℹ]  wrote "kubeconfig"
2018-07-02T11:23:48+01:00 [ℹ]  the cluster has 0 nodes
2018-07-02T11:23:48+01:00 [ℹ]  waiting for at least 3 nodes to become ready
2018-07-02T11:24:20+01:00 [ℹ]  the cluster has 3 nodes
2018-07-02T11:24:20+01:00 [ℹ]  node "ip-192-168-123-100.us-west-2.compute.internal" is ready
2018-07-02T11:24:20+01:00 [ℹ]  node "ip-192-168-171-21.us-west-2.compute.internal" is ready
2018-07-02T11:24:20+01:00 [ℹ]  node "ip-192-168-245-243.us-west-2.compute.internal" is ready
2018-07-02T11:24:22+01:00 [ℹ]  all command should work, try '/usr/local/bin/kubectl --kubeconfig kubeconfig get nodes'
2018-07-02T11:24:22+01:00 [ℹ]  EKS cluster "kube-rog-3" in "us-west-2" region is ready
```

Other clusters:
```sh
$ eksctl create cluster --cluster-name kube-rog-5 --nodes 3
$ eksctl create cluster --cluster-name kube-rog-7 --nodes 2 --region us-east-1 --auto-kubeconfig
```

The `eksctl` will create:
- The `kubeconfig` files in your current working directory for `kube-rog-3` and `kube-rog-5` clusters, and `~/.kube/eksctl/clusters/` directory for `kube-rog-7`.
- The Kubernetes cluster will create EC2 instances of type `m5.large` by default.
- The `--profile eks-usr-roger` or `export AWS_PROFILE=eks-usr-roger` can read the `credentials` file, but not the `config` file. You have to select the `region` with `--region us-east-1`.
- With `--auto-kubeconfig` eksctl will create credentials files under `~/.kube/eksctl/clusters/` directory.

### 2.4. Working with one Cluster

By default, the `eksctl` will create `kubeconfig` file, but if you want to get the `kubeconfig` for specific cluster already created, execute this command:
```
$ eksctl utils write-kubeconfig --cluster-name kube-rog-3 --kubeconfig kubeconfig.rog3
2018-07-02T12:12:55+01:00 [ℹ]  wrote kubeconfig file "kubeconfig.rog3"
```

Now, load the `kubeconfig.rog3` file.
```sh
$ unset KUBECONFIG
$ export KUBECONFIG=~/eks/kubeconfig.rog3

$ kubectl get nodes
NAME                                            STATUS    ROLES     AGE       VERSION
ip-192-168-105-229.us-west-2.compute.internal   Ready     <none>    1m        v1.10.3
ip-192-168-149-197.us-west-2.compute.internal   Ready     <none>    1m        v1.10.3
ip-192-168-221-35.us-west-2.compute.internal    Ready     <none>    1m        v1.10.3

$ kubectl cluster-info
Kubernetes master is running at https://C50Cxxx.yl4.us-west-2.eks.amazonaws.com

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

### 2.5. Working with multiple Clusters

If you have multiples clusters `kube-rog-3`, `kube-rog-5` and `kube-rog-7`, then you can use this:
```sh
$ unset KUBECONFIG; export KUBECONFIG=$KUBECONFIG:~/eks/kubeconfig.rog3:~/eks/kubeconfig.rog5:~/.kube/eksctl/clusters/kube-rog-7
```

```sh
$ kubectl config view

apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://0A9Dxxx.yl4.us-west-2.eks.amazonaws.com
  name: kube-rog-3.us-west-2.eksctl.io
- cluster:
    certificate-authority-data: REDACTED
    server: https://C50Cxxx.yl4.us-west-2.eks.amazonaws.com
  name: kube-rog-5.us-west-2.eksctl.io
- cluster:
    certificate-authority-data: REDACTED
    server: https://AAE0xxx.yl4.us-east-1.eks.amazonaws.com
  name: kube-rog-7.us-east-1.eksctl.io
contexts:
- context:
    cluster: kube-rog-3.us-west-2.eksctl.io
    user: usr-123@kube-rog-3.us-west-2.eksctl.io
  name: usr-123@kube-rog-3.us-west-2.eksctl.io
- context:
    cluster: kube-rog-5.us-west-2.eksctl.io
    user: usr-123@kube-rog-5.us-west-2.eksctl.io
  name: usr-123@kube-rog-5.us-west-2.eksctl.io
- context:
    cluster: kube-rog-7.us-east-1.eksctl.io
    user: usr-123@kube-rog-7.us-east-1.eksctl.io
  name: usr-123@kube-rog-7.us-east-1.eksctl.io
current-context: usr-123@kube-rog-5.us-west-2.eksctl.io
kind: Config
preferences: {}
users:
- name: usr-123@kube-rog-3.us-west-2.eksctl.io
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - token
      - -i
      - kube-rog-3
      command: heptio-authenticator-aws
      env: null
- name: usr-123@kube-rog-5.us-west-2.eksctl.io
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - token
      - -i
      - kube-rog-5
      command: heptio-authenticator-aws
      env: null
- name: usr-123@kube-rog-7.us-east-1.eksctl.io
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - token
      - -i
      - kube-rog-7
      command: heptio-authenticator-aws
      env: null
```

To switch between different clusters, to use the `use-context` param.
```sh
$ kubectl config use-context usr-123@kube-rog-3.us-west-2.eksctl.io
Switched to context "usr-123@kube-rog-3.us-west-2.eksctl.io".

$ kubectl get nodes
NAME                                            STATUS    ROLES     AGE       VERSION
ip-192-168-123-100.us-west-2.compute.internal   Ready     <none>    1h        v1.10.3
ip-192-168-171-21.us-west-2.compute.internal    Ready     <none>    1h        v1.10.3
ip-192-168-245-243.us-west-2.compute.internal   Ready     <none>    1h        v1.10.3

$ kubectl config use-context usr-123@kube-rog-5.us-west-2.eksctl.io
Switched to context "usr-123@kube-rog-5.us-west-2.eksctl.io".

$ kubectl get nodes
NAME                                            STATUS    ROLES     AGE       VERSION
ip-192-168-105-229.us-west-2.compute.internal   Ready     <none>    24m       v1.10.3
ip-192-168-149-197.us-west-2.compute.internal   Ready     <none>    24m       v1.10.3
ip-192-168-221-35.us-west-2.compute.internal    Ready     <none>    24m       v1.10.3

$ kubectl config use-context usr-123@kube-rog-7.us-east-1.eksctl.io
Switched to context "usr-123@kube-rog-7.us-east-1.eksctl.io".

$ kubectl get nodes
NAME                              STATUS    ROLES     AGE       VERSION
ip-192-168-107-81.ec2.internal    Ready     <none>    22h       v1.10.3
ip-192-168-131-235.ec2.internal   Ready     <none>    22h       v1.10.3

$ kubectl get all --all-namespaces
NAMESPACE     NAME                            READY     STATUS    RESTARTS   AGE
kube-system   pod/aws-node-f97p7              1/1       Running   1          23h
kube-system   pod/aws-node-pxfhl              1/1       Running   1          23h
kube-system   pod/kube-dns-64b69465b4-z5cnr   3/3       Running   0          23h
kube-system   pod/kube-proxy-89r6j            1/1       Running   0          23h
kube-system   pod/kube-proxy-x64tm            1/1       Running   0          23h

NAMESPACE     NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)         AGE
default       service/kubernetes   ClusterIP   10.100.0.1    <none>        443/TCP         23h
kube-system   service/kube-dns     ClusterIP   10.100.0.10   <none>        53/UDP,53/TCP   23h

NAMESPACE     NAME                        DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
kube-system   daemonset.apps/aws-node     2         2         2         2            2           <none>          23h
kube-system   daemonset.apps/kube-proxy   2         2         2         2            2           <none>          23h

NAMESPACE     NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/kube-dns   1         1         1            1           23h

NAMESPACE     NAME                                  DESIRED   CURRENT   READY     AGE
kube-system   replicaset.apps/kube-dns-64b69465b4   1         1         1         23h
```

Further `eksctl` commands:
- https://eksctl.io

## 3. Working with the Cluster

### 3.1.
