# Deploying Applications on Service Mesh

## References:
* Kubernetes By Example: http://kubernetesbyexample.com

## Tested with:
- Minishift v1.11.0+4459917
- Kubernetes 3.7
- istio 0.5.0
- VirtualBox 5.1.30
- macOS High Sierra, version 10.13.2 (17C88)

## 1. Hello2 App on Service Mesh

### 1.1. Deploy Hello2
```bash
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd service-mesh-workshop/labs/kube/04-deploying-on-service-mesh/

$ oc apply -f hello2-deploy.yaml
```

Check deployment:
```bash
$ oc get pods -n hello2-ns -o wide
NAME                         READY     STATUS    RESTARTS   AGE       IP            NODE
hello2-v1-819303223-csl7j    1/1       Running   0          20m       172.17.0.20   localhost
hello2-v2-3569402317-5t2jz   1/1       Running   0          38m       172.17.0.19   localhost

## the name of container can be used as parameter
$ oc exec hello2-v2-3569402317-5t2jz -c helloworld -n hello2-ns -- ps -aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
1000090+     1  0.0  0.0   4336     0 ?        Ss   10:14   0:00 /bin/sh -c python app.py
1000090+     7  0.1  0.5 103972 11044 ?        S    10:14   0:01 python app.py
1000090+     9  0.0  0.1  19188  2320 ?        Rs   10:31   0:00 ps -aux

## calling the API from same container
$ oc exec hello2-v1-819303223-csl7j -n hello2-ns -- curl -s localhost:5000/hello
$ oc exec hello2-v2-3569402317-5t2jz -n hello2-ns -- curl -s localhost:5000/hello
$ oc exec hello2-v1-819303223-csl7j -n hello2-ns -- curl -s 172.17.0.20:5000/hello
$ oc exec hello2-v2-3569402317-5t2jz -n hello2-ns -- curl -s 172.17.0.19:5000/hello

$ oc logs hello2-v2-3569402317-5t2jz -c helloworld -n hello2-ns -f
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
 172.17.0.19 - - [20/Feb/2018 10:33:22] "GET /hello HTTP/1.1" 200 -
 172.17.0.19 - - [20/Feb/2018 10:33:27] "GET /hello HTTP/1.1" 200 -
 172.17.0.19 - - [20/Feb/2018 10:33:29] "GET /hello HTTP/1.1" 200 -
```

### 1.2. Expose Hello2 as ClusterIP Service
```bash
$ oc apply -f hello2-svc.yaml
```

Check services:
```bash
$ oc get svc -n hello2-ns -o wide
NAME         CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE       SELECTOR
hello2-svc   172.30.19.113   <none>        6000/TCP   1m        app=hello2

## remote access (ssh) to Openshift: calling it from same container
$ minishift ssh --profile openshift0 -- curl -s 172.17.0.19:5000/hello
Hello version: v2, instance: hello2-v2-3569402317-5t2jz

## remote access (ssh) to Openshift: calling it through ClusterIP Service
$ minishift ssh --profile openshift0 -- curl -s 172.30.19.113:6000/hello
Hello version: v1, instance: hello2-v1-819303223-csl7j
$ minishift ssh --profile openshift0 -- curl -s 172.30.19.113:6000/hello
Hello version: v2, instance: hello2-v2-3569402317-5t2jz
```

### 1.3. Inject sidecar to Hello2
```bash
$ istioctl kube-inject -f hello2-deploy.yaml -o hello2-deploy-istio.yaml
```

Exploring `hello2-deploy-istio.yaml`:
```bash
$ cat hello2-deploy-istio.yaml
```
You will see 2 Init Container and 1 API Proxy:
```
...
spec:
  containers:
  - image: istio/examples-helloworld-v1
    name: helloworld
    ...
  - image: docker.io/istio/proxy:0.5.0
    name: istio-proxy
...
  initContainers:
  - image: docker.io/istio/proxy_init:0.5.0
    name: istio-init
    ...
  - image: alpine
    name: enable-core-dump
...
```

### 1.4. Redeploy Hello2
```bash
$ oc apply -f hello2-deploy-istio.yaml

## add ssc
$ oc adm policy add-scc-to-user privileged -z hello2-sa -n hello2-ns

## deploy ingress
$ oc apply -f hello2-ing.yaml
```
Calling the service through ingress:
```bash
$ curl -s eval $(minishift ip):80/hello
```

### 1.5. Explore Hello2 by using `oc` commands and through Weave Scope
```bash
$ oc get all -n hello2-ns
```

## 2.  GIS PoC on Service Mesh

### 2.1. Inject sidecar and deploy
```bash
$ oc apply -f gis-test1.yaml                                        ## namespace is test1-ns
$ istioctl kube-inject -f gis-test1.yaml -o gis-test1-istio.yaml    ## inject sidecar
$ oc apply -f gis-test1-istio.yaml                                  ## redeploy gis-test1
```

### 2.2. Explore App running in Service Mesh
```bash
$ oc get all -n test1-ns
$ curl -s <public-hostname>:<port>/<defined-path-ingress>
```
