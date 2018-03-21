# Coarse and fine grained Traffic Management with Ingress and Registry/Discovery Service

The aim is redirecting the incomming traffic from external API client to target API by adding the Ingress Controller. Once done, all incomming traffic pass through the Ingress Controll and it will be able to manage (filter, check attributes, reject, block, authenticate, etc.) that traffic.

__Kubernetes' Primitives used:__

* Deployment
* Pods
* Services
* Ingress Resources
* Ingress Controller

## 1) Chose the Ingress Controller:

* NGINX Ingress Controller (based on NGINX)
* HAProxy Ingress Controller (based on HAProxy)
* Linkerd Ingress Controller
* Traefik Ingress Controller
* Heptio Contour (based on Envoy Proxy)
* Istio Ingress Controller (based on Envoy Proxy)
* Gloo Ingress Controller (based on Envoy Proxy)

## 2) Install the Istio Ingress Controller only:

We are going to use the Istio Ingress Controller (https://istio.io/docs/tasks/traffic-management/ingress.html) only, not Istio Pilot and not Envoy Proxy as Sidecar.

```bash
$ git clone https://github.com/istio/istio
$ cd istio
$ git checkout tags/0.6.0
$ ./install/updateVersion.sh -m true -a "docker.io/istio,0.6.0"
$ kubectl apply -f install/kubernetes/components/istio-ns.yaml
$ kubectl apply -f install/kubernetes/components/istio-config.yaml
$ kubectl apply -f install/kubernetes/components/istio-pilot.yaml
$ kubectl apply -f install/kubernetes/components/istio-ingress.yaml
```

Check if Istio Ingress Controller and Pilot (discovery) were deployed successfully:
```bash
$ kubectl get deploy,po,svc -n istio-system -o wide
NAME                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS              IMAGES                                                    SELECTOR
deploy/istio-ingress   1         1         1            1           2m        istio-ingress           docker.io/istio/proxy:0.6.0                               istio=ingress
deploy/istio-pilot     1         1         1            1           8m        discovery,istio-proxy   docker.io/istio/pilot:0.6.0,docker.io/istio/proxy:0.6.0   istio=pilot

NAME                                READY     STATUS    RESTARTS   AGE       IP            NODE
po/istio-ingress-79778d5764-sxt2c   1/1       Running   0          2m        172.17.0.11   kube0
po/istio-pilot-66c6d5fb46-kghmj     2/2       Running   0          8m        172.17.0.10   kube0

NAME                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                               AGE       SELECTOR
svc/istio-ingress   LoadBalancer   10.110.84.84    <pending>     80:32148/TCP,443:31183/TCP            2m        istio=ingress
svc/istio-pilot     ClusterIP      10.106.74.174   <none>        15003/TCP,8080/TCP,9093/TCP,443/TCP   8m        istio=pilot
```

Checking the Istio Ingress and Pilot logs:
```bash
$ kubectl logs -l istio=pilot -n istio-system -c discovery
$ kubectl logs -l istio=pilot -n istio-system -c istio-proxy
$ kubectl logs -l istio=ingress -n istio-system
```

## 3) Deploying HelloWorld App and Creating an Ingress Resource

We are going to use HelloWorld App, the same previously used in `01-delivering-on-k8s`, in fact we have to add only the Ingress Resource.
Below I'm re-deploying all HelloWorld App including the Ingress Resource for the NodePort Service.

```bash
$ cd service-mesh-workshop/labs/kube/02-ingress/
$ kubectl delete ns hello
$ kubectl apply -f hello-app-with-ingress.yaml
```

Check if HelloWorl App is running:
```bash
$ kubectl get pod,svc,ing -n hello
```

And you should view that HelloWorld through NodePort Service (`hello-svc-np`) is managed by the Istio Ingress:
```bash
$ kubectl logs -l istio=ingress -n istio-system
...
[2018-03-21 15:53:01.778][14][info][upstream] external/envoy/source/common/upstream/cluster_manager_impl.cc:391] removing cluster out.hello-svc-np.hello.svc.cluster.local|http
[2018-03-21 15:56:37.851][14][info][upstream] external/envoy/source/common/upstream/cluster_manager_impl.cc:356] add/update cluster out.hello-svc-np.hello.svc.cluster.local|http
```

## 4) Calling HelloWord App (NodePort Service) through Istio Ingress Controller

Since that Istio Ingress Controller has been exposed as a `LoadBalancer` Service, the EdgeProxy will be working as `transparent-proxy` and the Istio Ingress Controller will have a public and accesible IP address. Now, we have to call the HellowWorld App through the Istio Ingress Controller, specifically by using the EdgeProxy's IP address and `http` port.

```bash
$ kubectl get svc -l istio=ingress -n istio-system -o wide
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE       SELECTOR
istio-ingress   LoadBalancer   10.110.84.84   <pending>     80:32148/TCP,443:31183/TCP   16m       istio=ingress

$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
```

* We are using `.spec.ports[0].nodePort` because `.spec.ports[0].port` has not been opened or NATed by Minikube (Virtualbox VM).
* We are using `minikube ip` to get the public IP address of Minikube VM.
* In a real cloud scenario, the IP address and Port must be configured synced properly.
