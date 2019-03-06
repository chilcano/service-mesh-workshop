# Delivering APIs into Kubernetes

## 1) Deploy HelloWorld App:

```sh
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd $PWD/service-mesh-workshop/labs

$ oc apply -f 01-delivering-on-k8s/hello-app.yaml          ## for openshift/minishift
$ kubectl apply -f 01-delivering-on-k8s/hello-app.yaml     ## for kubernetes/minikube
```

## 2) Check deployment:

```bash
$ kubectl get pods,svc -n hello -o wide
```

## 3) Call to API through Kubernetes Services (ClusterIP, LoadBalancer and NodePort SVC)

Get details of all SVC available for HelloWorld App:
```sh
$ kubectl describe svc hello-svc-cip -n hello
$ kubectl describe svc hello-svc-lb -n hello
$ kubectl describe svc hello-svc-np -n hello
```

__Explanation:__

* __ClusterIP__: Exposes the service on a cluster-internal IP. Choosing this value makes the service only reachable from within the cluster. This is the default `ServiceType`. It means that `NodePort` and `LoadBalancer` are `ClusterIP` too.
* __NodePort__: Exposes the service on each Node’s IP at a static port (the `NodePort`). A `ClusterIP` service, to which the `NodePort` service will route, is automatically created. You’ll be able to contact the `NodePort` service, from outside the cluster, by requesting `<NodeIP>:<NodePort>`.
* __LoadBalancer__: Exposes the service externally using a cloud provider’s load balancer. `NodePort` and `ClusterIP` services, to which the external load balancer will route, are automatically created.
* To call any service, the remote access (SSH) allways is required, except if the microservice has been published as LoadBalancer SVC.
* If you are using Minikube (VirtualBox VM), which it has not an EdgeProxy (Load Balancer) and it has a virtual NIC that uses NAT, the microservices exposed as `NodePort` and `LoadBalancer` SVN can be reached.
* See `EXTERNAL-IP=<pending>` for `LoadBalancer` SVC, it means that Minikube (VirtualBox VM) can not assign a IP address to `LoadBalancer` SVC.
* `NodePort` and `ClusterIP` are the Kubernetes services most used to expose microservices to API clients (consumers) out of the Containerised Platform, but it's mandatory using an Ingress Controller (TLS termination, routing, balancing, extend the authentication, etc.) and create Ingress Resources (dynamic route definition).

### 3.1) Calling ClusterIP SVC

```sh
$ export HELLO_SVC_CLUSTERIP=$(kubectl get svc/hello-svc-cip -n hello -o jsonpath='{.spec.clusterIP}'):$(kubectl get svc/hello-svc-cip -n hello -o jsonpath='{.spec.ports[0].port}')
$ minikube ssh -- curl http://${HELLO_SVC_CLUSTERIP}/hello
```

* We are getting remote SSH access through `minikube ssh`, once done the `curl xyz` command is executed.

### 3.2) Calling LoadBalancer SVC

```sh
$ export HELLO_SVC_LOADBALANCER=$(kubectl get svc hello-svc-lb -n hello -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s http://$(minikube ip):${HELLO_SVC_LOADBALANCER}/hello
```

* We are using `.spec.ports[0].nodePort` because `.spec.ports[0].port` has not been opened or NATed by Minikube (Virtualbox VM).

### 3.3) Calling NodePort SVC

```sh
$ export HELLO_SVC_NODEPORT=$(kubectl get svc hello-svc-np -n hello -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s http://$(minikube ip):${HELLO_SVC_NODEPORT}/hello
```
