# Secure, coarse and fine grained Traffic Management with Ingress, Sidecar and Network Policy

__Kubernetes' Primitives used:__

* Deployment
* Pods
* Services
* Ingress Resources
* Ingress Controller
* Init Container and Sidecar Container
* Network Policy 

## 1) Deploying HelloWorld v3 with Ingress

Clonning this workshop:
```sh
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd $(PWD)/service-mesh-workshop/labs/kube
```

Previously you have to install `02-ingress/hello-app-with-ingress.yaml`. Once done, install `hello-v3.yaml`.
```sh
$ kubectl apply -f 02-ingress/hello-v3.yaml
```

Once done you can install the `hello-v3.yaml`
```sh
$ kubectl apply -f 03-ingress-sidecar/hello-v3.yaml
```

Check deployment:
```sh
$ kubectl get pods,svc,ing -n hello
NAME                           READY     STATUS    RESTARTS   AGE
po/hello-v1-69c9685b5-lqznm    1/1       Running   0          18m
po/hello-v2-54f5878c79-6gqvw   1/1       Running   0          18m
po/hello-v3-d9b99d69d-tqtsr    1/1       Running   0          9m

NAME                   TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
svc/hello-svc-np       NodePort   10.104.167.181   <none>        5030:31683/TCP   18m
svc/hello-svc-np-e2e   NodePort   10.101.169.227   <none>        5040:30756/TCP   9m

NAME                HOSTS               ADDRESS   PORTS     AGE
ing/hello-ing       *                             80        18m
ing/hello-ing-e2e   v3.helloworld.com             80        9m
```

The Ingress `ing/hello-ing-e2e` and the NodePort Service `svc/hello-svc-np-e2e` will route all traffic to HelloWorld v3 if that traffic is for `v3.helloworld.com`.

### 1.1) Calling HelloWorld v3 through Istio Ingress Controller, previous Ingress Resource and NodePort Service.

The Ingress `ing/hello-ing` and the NodePort Service `svc/hello-svc-np` will route all traffic to HelloWorld v1, v2 and v3.

```sh
$ kubectl get svc -l istio=ingress -n istio-system -o wide
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE       SELECTOR
istio-ingress   LoadBalancer   10.110.84.84   <pending>     80:32148/TCP,443:31183/TCP   16m       istio=ingress

$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')

$ curl -s http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v1, instance: hello-v1-69c9685b5-lqznm

$ curl -s http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v2, instance: hello-v2-54f5878c79-6gqvw

$ curl -s http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v3, instance: hello-v3-d9b99d69d-tqtsr
```

### 1.2) Calling HelloWorld v3 through Istio Ingress Controller, new Ingress Resource and new NodePort Service.

Since we want to call the HelloWorld v3 (`v3.helloworld.com`), the Ingress `ing/hello-ing-e2e` and the NodePort Service `svc/hello-svc-np-e2e` will be used to route all incomming traffic.

```sh
$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')

$ curl -s -H "Host: v3.helloworld.com" http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v3, instance: hello-v3-d9b99d69d-tqtsr
...
$ curl -s -H "Host: v3.helloworld.com" http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v3, instance: hello-v3-d9b99d69d-tqtsr
```

## 2) Deploying HelloWorld v3 with Ingress, injected Init and Sidecar Container

### 2.1) Injecting Init and Sidecar Container

The `istioctl` is a command line that will update the `hello-v3.yaml` and insert the proper configuration to bootstrap an Init and Sidecar Container.

```sh
$ curl -kL https://git.io/getLatestIstio | sed 's/curl/curl -k /g' | ISTIO_VERSION=0.6.0 sh -
$ export PATH="$PATH:${PWD}/istio-0.6.0/bin"

$ istioctl kube-inject -f 03-ingress-sidecar/hello-v3.yaml -o 03-ingress-sidecar/hello-v3-istio.yaml
```

__Exploring `03-ingress-sidecar/hello-v3-istio.yaml`__

```yaml
...
spec:
  containers:
  - image: istio/examples-helloworld-v1
    name: helloworld
    env:
    - name: SERVICE_VERSION
      value: v3
    ports:
    - containerPort: 5000
  - image: docker.io/istio/proxy:0.6.0
    name: istio-proxy
...
  initContainers:
  - image: docker.io/istio/proxy_init:0.6.0
    name: istio-init
    ...
  - image: alpine
    name: enable-core-dump
...
```

* The `istioctl` is part of Istio bundle, we have to use the same version that Istio is running in Kubernetes, because `istioctl` will inject the configuration for that version accordingly.
* You will see 2 Init Containers (`istio-init` and `enable-core-dump`) and 2 Containers, the HelloWorld v3 (`helloworld`) and Sidecar (`istio-proxy`).
* The `istio-init` and `enable-core-dump`, both Init Containers are going to bootstrap security configuration at container level (add an `iptables` rule and set `unlimited`).
* The Sidecar container `istio-proxy` will be executed in the same Pod that main container is hosted, the Sidecar will work as Gateway or Proxy and will implement Service Mesh's functionalities needed to increase the security. e.g.:
  - Automatic TLS Certificate management (enrolment, propagation, confifuration, validation, renewal, etc.).
  - Secure Management (propagation, renewal, validation, etc.) of Secrets.
  - Security Policies over Traffic Network.
  - Extend the Security by adding Authentication and Authorization Servers.
  - Etc.

### 2.2) Redeploy the HelloWorld v3 with injected Init and Sidecar Containers

Openshift needs to add a Security Context Constrain (`scc`):
```sh
$ oc adm policy add-scc-to-user privileged -z hello-sa -n hello
```

Delete the previous HelloWorld v3 to re-deploy the HelloWorld v3 with sidecar-injected.
```sh
$ kubectl delete -f 03-ingress-sidecar/hello-v3.yaml
$ kubectl apply -f 03-ingress-sidecar/hello-v3-istio.yaml
```

Checking if everything (Pods, Ingress rule, etc.) is working.
```sh
$ kubectl get pod,svc,ing -n hello
$ kubectl logs -l version=v3 -n hello -c istio-proxy
$ kubectl logs -l istio=ingress -n istio-system
...
[2018-04-04 14:02:29.982][14][info][upstream] external/envoy/source/common/upstream/cluster_manager_impl.cc:356] add/update cluster out.hello-svc-np-e2e.hello.svc.cluster.local|http
[2018-04-04T14:04:20.780Z] "GET /hello HTTP/1.1" 200 - 0 55 207 205 "172.17.0.1" "curl/7.54.0" "575fecd2-b124-4b16-b7e7-32964e9986ef" "v3.helloworld.com" "172.17.0.11:5000"
[2018-04-04T14:04:22.818Z] "GET /hello HTTP/1.1" 200 - 0 55 170 170 "172.17.0.1" "curl/7.54.0" "c836ff9a-845b-4f90-bd05-c479e5fcfe92" "v3.helloworld.com" "172.17.0.11:5000"
[2018-04-04T14:04:24.323Z] "GET /hello HTTP/1.1" 200 - 0 55 172 171 "172.17.0.1" "curl/7.54.0" "7d78887f-de70-4a79-a450-62948d87a4b7" "v3.helloworld.com" "172.17.0.11:5000"
[2018-04-04T14:04:26.183Z] "GET /hello HTTP/1.1" 200 - 0 55 160 159 "172.17.0.1" "curl/7.54.0" "22b9b6e1-0d83-4b19-8d3b-bc7baa2cd7d4" "v3.helloworld.com" "172.17.0.11:5000"
[2018-04-04T14:11:53.500Z] "GET /hello HTTP/1.1" 200 - 0 54 264 263 "172.17.0.1" "curl/7.54.0" "e5677637-74dd-48b5-9c2a-870173f89534" "192.168.99.100:31338" "172.17.0.9:5000"
[2018-04-04T14:11:55.592Z] "GET /hello HTTP/1.1" 200 - 0 55 314 313 "172.17.0.1" "curl/7.54.0" "f4712f32-45f4-47e0-9d48-5aec34800907" "192.168.99.100:31338" "172.17.0.10:5000"
[2018-04-04T14:11:57.482Z] "GET /hello HTTP/1.1" 200 - 0 55 304 302 "172.17.0.1" "curl/7.54.0" "7ead28ef-8b71-42ea-8d5c-4c16a93c2f08" "192.168.99.100:31338" "172.17.0.11:5000"
```

### 2.3) Calling HelloWorld v3 with sidecar injected through Istio Ingress

```sh
$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')

$ curl -s -H "Host: v3.helloworld.com" http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
```

Verifyig HelloWorld v3's traffic is being routed and secured properly.
```sh
$ kubectl logs -l version=v3 -n hello -c helloworld
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
127.0.0.1 - - [04/Apr/2018 14:04:20] "GET /hello HTTP/1.1" 200 -
127.0.0.1 - - [04/Apr/2018 14:04:22] "GET /hello HTTP/1.1" 200 -
127.0.0.1 - - [04/Apr/2018 14:04:24] "GET /hello HTTP/1.1" 200 -
127.0.0.1 - - [04/Apr/2018 14:04:26] "GET /hello HTTP/1.1" 200 -
127.0.0.1 - - [04/Apr/2018 14:11:57] "GET /hello HTTP/1.1" 200 -

$ kubectl logs -l version=v3 -n hello -c istio-proxy
2018-04-04T14:02:32.476639Z	info	Version root@a28f609ab931-docker.io/istio-0.6.0-2cb09cdf040a8573330a127947b11e5082619895-Clean
2018-04-04T14:02:32.476727Z	info	Proxy role: model.Proxy{Type:"sidecar", IPAddress:"172.17.0.11", ID:"hello-v3-7cb4968687-f99b8.hello", Domain:"hello.svc.cluster.local"}
2018-04-04T14:02:32.477401Z	info	Effective config: binaryPath: /usr/local/bin/envoy
configPath: /etc/istio/proxy
connectTimeout: 10.000s
discoveryAddress: istio-pilot.istio-system:15003
discoveryRefreshDelay: 1.000s
drainDuration: 45.000s
parentShutdownDuration: 60.000s
proxyAdminPort: 15000
serviceCluster: hello
...
2018-04-04T14:02:32.477431Z	info	Monitored certs: []v1.CertSource{v1.CertSource{Directory:"/etc/certs/", Files:[]string{"cert-chain.pem", "key.pem", "root-cert.pem"}}}
[2018-04-04 14:02:32.568][13][info][main] external/envoy/source/server/server.cc:343] all clusters initialized. initializing init manager
[2018-04-04 14:02:32.578][13][info][upstream] external/envoy/source/server/lds_api.cc:60] lds: add/update listener 'virtual'
...
[2018-04-04 14:02:32.590][13][info][upstream] external/envoy/source/server/lds_api.cc:60] lds: add/update listener 'tcp_10.99.191.187_80'
[2018-04-04 14:02:32.594][13][info][config] external/envoy/source/server/listener_manager_impl.cc:579] all dependencies initialized. starting workers
[2018-04-04 14:02:33.752][13][info][upstream] external/envoy/source/common/upstream/cluster_manager_impl.cc:356] add/update cluster in.5000
[2018-04-04 14:02:34.424][13][info][upstream] external/envoy/source/server/lds_api.cc:60] lds: add/update listener 'http_172.17.0.11_5000'
2018-04-04T14:03:02.488689Z	info	Proxy availability zone:
2018-04-04T14:03:32.490845Z	info	Proxy availability zone:
[2018-04-04 14:03:32.595][13][info][main] external/envoy/source/server/drain_manager_impl.cc:63] shutting down parent after drain
2018-04-04T14:04:02.494403Z	info	Proxy availability zone:
[2018-04-04T14:04:20.781Z] "GET /hello HTTP/1.1" 200 - 0 55 205 204 "172.17.0.1" "curl/7.54.0" "575fecd2-b124-4b16-b7e7-32964e9986ef" "v3.helloworld.com" "127.0.0.1:5000"
[2018-04-04T14:04:22.818Z] "GET /hello HTTP/1.1" 200 - 0 55 170 169 "172.17.0.1" "curl/7.54.0" "c836ff9a-845b-4f90-bd05-c479e5fcfe92" "v3.helloworld.com" "127.0.0.1:5000"
[2018-04-04T14:04:24.324Z] "GET /hello HTTP/1.1" 200 - 0 55 171 170 "172.17.0.1" "curl/7.54.0" "7d78887f-de70-4a79-a450-62948d87a4b7" "v3.helloworld.com" "127.0.0.1:5000"
[2018-04-04T14:04:26.183Z] "GET /hello HTTP/1.1" 200 - 0 55 159 159 "172.17.0.1" "curl/7.54.0" "22b9b6e1-0d83-4b19-8d3b-bc7baa2cd7d4" "v3.helloworld.com" "127.0.0.1:5000"
2018-04-04T14:04:32.496565Z	info	Proxy availability zone:
2018-04-04T14:05:02.498463Z	info	Proxy availability zone:
...
2018-04-04T14:08:02.513913Z	info	Proxy availability zone:
2018-04-04T14:08:02.514139Z	info	Availability zone not set, proxy will default to not using zone aware routing.
[2018-04-04T14:11:57.485Z] "GET /hello HTTP/1.1" 200 - 0 55 300 299 "172.17.0.1" "curl/7.54.0" "7ead28ef-8b71-42ea-8d5c-4c16a93c2f08" "192.168.99.100:31338" "127.0.0.1:5000"
```

### 2.4) Updating



## 3) Conclusions about using Istio Ingress, Pilot and Sidecar

Once deployed Ingress and Sidecar we are able to implement security over the traffic (L7 Firewall and L4/L7 Traffic Filtering). But by using Kubernetes Network Policies we are able to reduce the attack surface of the Distributed Applications at Pods level (L3/L4 Firewall). In fact, the best security practice is to use both recommendations (Init/Sidecar Container and Kubernetes Network Policies) where we will be able to implement end-to-end security.

Istio Pilot helps to improve the traceability and fine grained traffic control for each API, and by using Sidecar Container those new traffic rules can be spread to every API.

### 3.1) Identifying Attack Vectors

Below you can see different attack vectors for HelloWord v3 as target.

```sh
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
```

### 3.2) Implementing Kubernetes Network Policy (L3/L4 Firewall)

Kubernetes uses Container Network Interface (CNI) plug-ins to orchestrate networking through the available Software-defined Networking (SDN). Every time a POD is initialized or removed, the default CNI plug-in is called with the default configuration. This CNI plug-in creates a pseudo interface, attaches it to the relevant underlay network (SDN), sets the IP and routes and maps it to the POD namespace.

In order to use Kubernetes Network Policy, Kubernetes needs CNI enabled and Network Provider (SDN) implementation.
- Choosing a CNI Network Provider for Kubernetes (https://chrislovecnm.com/kubernetes/cni/choosing-a-cni-provider): Cilium, Weave Net, Calico, Flannel, ..
- Enabling CNI in Minikube: `minikube start --network-plugin cni`

__Step 1: Installing Minikube with CNI__
```sh
$ minikube start \
--vm-driver=virtualbox \
--profile kube0 \
--kubernetes-version=v1.8.0  \
--extra-config apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota" \
--network-plugin cni \
--bootstrapper localkube \
--feature-gates CustomResourceValidation=true \
--cpus 4 \
--memory 4096 \
--iso-url file:///Users/Chilcano/Downloads/minikube-v0.25.1.iso
```

__Step 2: Installing Cilium as Kubernetes Network Provider (SDN) implementation__
```sh
$ kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/cilium.yaml
```

__Step 3: Demo #1: Deploying sample app__

Ref.: http://cilium.readthedocs.io/en/latest/gettingstarted/minikube/#step-2-deploy-the-demo-application

```sh
$ kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/demo.yaml
$ kubectl get pods,svc
```

Each pod will be represented in Cilium as an Endpoints. We can invoke the cilium tool inside the Cilium pod to list them:
```sh
$ kubectl get pods -l k8s-app=cilium -n kube-system
NAME           READY     STATUS    RESTARTS   AGE
cilium-ltswq   1/1       Running   0          4m

$ kubectl exec cilium-ltswq -n kube-system -- cilium endpoint list

ENDPOINT   POLICY (ingress)   POLICY (egress)   IDENTITY   LABELS (source:key[=value])               IPv6                 IPv4            STATUS
           ENFORCEMENT        ENFORCEMENT
3978       Disabled           Disabled          57572      k8s:id=app3                               f00d::a0f:0:0:f8a    10.15.25.58     ready
                                                           k8s:io.kubernetes.pod.namespace=default
15124      Disabled           Disabled          42120      k8s:id=app2                               f00d::a0f:0:0:3b14   10.15.101.61    ready
                                                           k8s:io.kubernetes.pod.namespace=default
28441      Disabled           Disabled          2097       k8s:id=app1                               f00d::a0f:0:0:6f19   10.15.106.144   ready
                                                           k8s:io.kubernetes.pod.namespace=default
29898      Disabled           Disabled          4547       reserved:health                           f00d::a0f:0:0:74ca   10.15.242.54    ready
45392      Disabled           Disabled          2097       k8s:id=app1                               f00d::a0f:0:0:b150   10.15.157.163   ready
                                                           k8s:io.kubernetes.pod.namespace=default
```
Policy enforcement is still disabled on all of these pods because no network policy has been imported yet which select any of the pods.

__Step 4: Demo #1: Apply an L3/L4 Policy__

Ref.: http://cilium.readthedocs.io/en/latest/gettingstarted/minikube/#step-3-apply-an-l3-l4-policy

```sh
$ cat l3_l4_policy.yaml

kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
#for k8s <1.7 use:
#apiVersion: extensions/v1beta1
metadata:
  name: access-backend
spec:
  podSelector:
    matchLabels:
      id: app1
  ingress:
  - from:
    - podSelector:
        matchLabels:
          id: app2
    ports:
    - port: 80
      protocol: TCP

$ kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/l3_l4_policy.yaml

$ kubectl exec cilium-ltswq -n kube-system -- cilium endpoint list

ENDPOINT   POLICY (ingress)   POLICY (egress)   IDENTITY   LABELS (source:key[=value])               IPv6                 IPv4            STATUS
           ENFORCEMENT        ENFORCEMENT
3978       Disabled           Disabled          57572      k8s:id=app3                               f00d::a0f:0:0:f8a    10.15.25.58     ready
                                                           k8s:io.kubernetes.pod.namespace=default
15124      Disabled           Disabled          42120      k8s:id=app2                               f00d::a0f:0:0:3b14   10.15.101.61    ready
                                                           k8s:io.kubernetes.pod.namespace=default
28441      Enabled            Disabled          2097       k8s:id=app1                               f00d::a0f:0:0:6f19   10.15.106.144   ready
                                                           k8s:io.kubernetes.pod.namespace=default
29898      Disabled           Disabled          4547       reserved:health                           f00d::a0f:0:0:74ca   10.15.242.54    ready
45392      Enabled            Disabled          2097       k8s:id=app1                               f00d::a0f:0:0:b150   10.15.157.163   ready
                                                           k8s:io.kubernetes.pod.namespace=default
```

__Step 5: Demon #1: Test L3/L4 Policy__

Ref.: http://cilium.readthedocs.io/en/latest/gettingstarted/minikube/#step-4-test-l3-l4-policy

Calling app2 to app1 on 80 port. This works.
```sh
$ kubectl exec app2 -- curl -s app1-service.default
<html><body><h1>It works!</h1></body></html>
```

Calling app3 to app1 on 80 port. This never works and will not receive answer.
```sh
$ kubectl exec app3 -- curl -s app1-service.default
command terminated with exit code 7
```

__Step 5: Demon #2: L3/L4 Cilium Policy between Istio Ingress and Pods with Envoy Proxy as Sidecar Container__

Previously you have to:
- Install the Istio Ingress.
- Install the `02-ingress/hello-app-with-ingress.yaml`
- Install the `03-ingress-sidecar/hello-v3.yaml` with Envoy Proxy injected as sidecar (`03-ingress-sidecar/hello-v3-istio.yaml`)
- Create a Network L3/L4 Policy (`03-ingress-sidecar/hello-v3-netpol.yaml`) for `03-ingress-sidecar/hello-v3-istio.yaml` and install it.

```yaml
$ cat 03-ingress-sidecar/hello-v3-netpol.yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: hello-v3
  namespace: hello
spec:
  podSelector:
    matchLabels:
      app: hello
      version: v3
  ingress:
  - ports:
    - protocol: TCP
      port: 5040
    from:
    - podSelector:
        matchLabels:
          istio: ingress
---
```
This policy allows incomming traffic from pod with label `istio: ingress` to pod with labels `app: hello` and `version: v3` over `5040` port.

Applying the policy.
```sh
$ kubectl apply -f 03-ingress-sidecar/hello-v3-netpol.yaml
```

Verify that policy has been applied.
```sh
$ kubectl exec cilium-ltswq -n kube-system -- cilium endpoint list
```

Now, test it by connecting to any pod different to `istio: ingress`. For example, use `hello-v1` or `hello-v2` pod. It should not work.
```sh
$ kubectl get pod -n hello
NAME                        READY     STATUS    RESTARTS   AGE
hello-v1-69c9685b5-znjw9    1/1       Running   0          28m
hello-v2-54f5878c79-qd2zx   1/1       Running   0          28m
hello-v3-7cb4968687-7x6xz   2/2       Running   0          22m

$ kubectl exec hello-v1-69c9685b5-znjw9 -n hello -- curl -s hello-svc-np-e2e:5040/hello
command terminated with exit code 6
```

But if you call `hello-v3` from pod with label `istio: ingress` it should work.
```sh
$ kubectl get pod -n istio-system
NAME                             READY     STATUS    RESTARTS   AGE
istio-ingress-564c984f48-nnp4s   1/1       Running   0          29m
istio-pilot-66c6d5fb46-dwxz4     2/2       Running   0          30m

$ kubectl exec istio-ingress-564c984f48-nnp4s -n istio-system -- curl -s hello-svc-np-e2e.hello:5040/hello
oci runtime error: exec failed: container_linux.go:265: starting container process caused "exec: \"curl\": executable file not found in $PATH"

command terminated with exit code 126
```

Ops!, the problem is that `istio: ingress` pod don't have `curl` installed. We can try to call `hello-v3` from the LoadBalancer Service that exposes the Ingress Controller.
```sh
$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s -H "Host: v3.helloworld.com" http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
```

We can install new pod with the same or new label `access: hello-v3` to call to `hello-v3`.
```sh
$ kubectl run malicious --rm -ti --labels="access=hello-v3" --image=radial/busyboxplus:curl
/ # curl -s http://hello-svc-np.hello:5030/hello
/ # curl -s -H "Host: v3.helloworld.com" http://hello-svc-np-e2e.hello:5040/hello
```

## 4) More Demos: Istio Bookinfo App with L3/L4 Cilium Policy

Refs:
- Using Istio to Improve End-to-End Security: https://istio.io/blog/2017/0.1-auth.html
- Using Network Policy with Istio: https://istio.io/blog/2017/0.1-using-network-policy.html
- Consuming External Web Services -  Egress Rules for HTTPS traffic: https://istio.io/blog/2018/egress-https.html
- Consuming External TCP Services - Egress rules for TCP traffic: https://istio.io/blog/2018/egress-tcp.html
