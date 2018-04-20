# Traffic Management with Ingress

The aim is redirecting the incomming traffic from external API client to target API by adding the Ingress Controller. Once done, all incomming traffic pass through the Ingress Controller and it will be able to manage (filter, check attributes, reject, block, authenticate, etc.) that traffic.

__Kubernetes' Primitives used:__

* Deployment
* Pods
* Services
* Ingress Resources
* Ingress Controller

## 1) Chose the Ingress Controller

* NGINX Ingress Controller (based on NGINX)
* HAProxy Ingress Controller (based on HAProxy)
* Linkerd Ingress Controller
* Traefik Ingress Controller
* Heptio Contour (based on Envoy Proxy)
* Istio Ingress Controller (based on Envoy Proxy)
* Gloo Ingress Controller (based on Envoy Proxy)

## 2) Install only the Istio Ingress Controller

We are going to use the Istio Ingress Controller (https://istio.io/docs/tasks/traffic-management/ingress.html) only, not Envoy Proxy as Sidecar.

__Observations:__
* The Istio Pilot is not used to increase the security over the traffic, it is used only as Service Registry.
* The `kubernetes/components/istio-config-updated.yaml` and `kubernetes/components/istio-ingress-updated.yaml` were updated to disable tracing and MTLS authentication (`controlPlaneAuthPolicy: NONE`) between Proxies.

```sh
$ git clone https://github.com/istio/istio istio-0.6.0
$ cd $(PWD)/istio-0.6.0
$ git checkout tags/0.6.0
$ ./install/updateVersion.sh -m true -a "docker.io/istio,0.6.0"
$ kubectl apply -f install/kubernetes/components/istio-ns.yaml
## istio-config-updated.yaml and istio-ingress-updated.yaml have been modified removing tracing, mixer, etc.
$ kubectl apply -f install/kubernetes/components/istio-config-updated.yaml
$ kubectl apply -f install/kubernetes/components/istio-pilot.yaml
$ kubectl apply -f install/kubernetes/components/istio-ingress-updated.yaml
```

Check if Istio Ingress Controller and Pilot (discovery) were deployed successfully:
```sh
$ kubectl get deploy,po,svc -n istio-system -o wide
$ kubectl logs -l istio=pilot -n istio-system -c discovery
$ kubectl logs -l istio=pilot -n istio-system -c istio-proxy
$ kubectl logs -l istio=ingress -n istio-system
```

## 3) Deploying HelloWorld App and creating an Ingress Resource

We are going to use HelloWorld App, the same previously used in `01-delivering-on-k8s`, in fact we have to add only the Ingress Resource.
Below I'm re-deploying all HelloWorld App including the Ingress Resource for the NodePort Service.

```sh
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd $(PWD)/service-mesh-workshop/labs

$ kubectl delete ns hello
$ kubectl apply -f 02-ingress/hello-app-with-ingress.yaml
```

Check if HelloWorld App is running:
```bash
$ kubectl get pod,svc,ing -n hello
```

And you should view that HelloWorld through NodePort Service (`hello-svc-np`) is managed by the Istio Ingress:
```sh
$ kubectl logs -l istio=ingress -n istio-system
...
[2018-03-21 15:53:01.778][14][info][upstream] external/envoy/source/common/upstream/cluster_manager_impl.cc:391] removing cluster out.hello-svc-np.hello.svc.cluster.local|http
[2018-03-21 15:56:37.851][14][info][upstream] external/envoy/source/common/upstream/cluster_manager_impl.cc:356] add/update cluster out.hello-svc-np.hello.svc.cluster.local|http
```

## 4) Calling HelloWord App (NodePort Service) through Istio Ingress Controller

Since that Istio Ingress Controller has been exposed as a `LoadBalancer` Service, the EdgeProxy will be working as `transparent-proxy` and the Istio Ingress Controller will have a public and accesible IP address. Now, we have to call the HellowWorld App through the Istio Ingress Controller, specifically by using the EdgeProxy's IP address and `http` port.

```sh
$ kubectl get svc -l istio=ingress -n istio-system -o wide
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE       SELECTOR
istio-ingress   LoadBalancer   10.110.84.84   <pending>     80:32148/TCP,443:31183/TCP   16m       istio=ingress

$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v2, instance: hello-v2-54f5878c79-v5znq

$ curl -s http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v1, instance: hello-v1-69c9685b5-dgnhq
```

* We are using `.spec.ports[0].nodePort` because `.spec.ports[0].port` has not been opened or NATed by Minikube (Virtualbox VM).
* We are using `minikube ip` to get the public IP address of Minikube VM.
* In a real cloud scenario, the IP address and Port must be configured synced properly.
