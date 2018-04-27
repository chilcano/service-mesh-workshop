# Traffic Management with Ingress, Sidecar and Network Policy

__Kubernetes' Primitives used:__

* Deployment
* Pods
* Services
* Ingress Resources
* Ingress Controller
* Init Container and Sidecar Container
* Network Policy

## 1) Towards the end-to-end security (L3, L4 and L7 Policy Enforcement)

Once deployed Ingress and Sidecar we are able to implement security over the traffic (L7 Firewall and L4/L7 Traffic Filtering), but the attack surface is still the same, it means that the Pods and Containers are still having open ports and listening for incomming traffic (HTTP, TCP, UDP, etc.).

To solve or reduce the attack surface of the Distributed Applications at Pods level (L3/L4 Firewall) we should use the Kubernetes Network Policies.
The best security practices are to use both recommendations (Init/Sidecar Container and Kubernetes Network Policies), once accomplished we will be able to implement end-to-end security.

## 2) Implementing Kubernetes Network Policy (L3/L4 Firewall)

Kubernetes uses Container Network Interface (CNI) plug-ins to orchestrate networking through the available Software-defined Networking (SDN). Every time a POD is initialized or removed, the default CNI plug-in is called with the default configuration. This CNI plug-in creates a pseudo interface, attaches it to the relevant underlay network (SDN), sets the IP and routes and maps it to the POD namespace.

In order to use Kubernetes Network Policy, Kubernetes needs CNI enabled and Network Provider (SDN) implementation.
- Choosing a CNI Network Provider for Kubernetes (https://chrislovecnm.com/kubernetes/cni/choosing-a-cni-provider): Cilium, Weave Net, Calico, Flannel, ..
- Enabling CNI in Minikube: `minikube start --network-plugin cni`

__Step 1: Installing Minikube with CNI__

```sh
$ git clone https://github.com/chilcano/service-mesh-workshop
$ cd $(PWD)/service-mesh-workshop/labs
$ . 00-k8s/k8s-minikube-start.sh kube0
```

__Step 2: Installing Cilium as Kubernetes Network Provider (SDN/CNI) implementation__

```sh
$ kubectl create clusterrolebinding kube-system-default-binding-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
$ kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/addons/etcd/standalone-etcd.yaml

## If you don't want Cilium works as L7 Firewall, then run the above command. Istio works as L7 Firewall.
$ kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/1.8/cilium.yaml

## If you want Cilium works as L7 Firewall, then enable Cilium with `sidecar-http-proxy: "true"`
$ curl -s https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/kubernetes/1.8/cilium.yaml | \
  sed -e 's/sidecar-http-proxy: "false"/sidecar-http-proxy: "true"/' | \
  kubectl create -f -
```

__Step 3: Demo about L3/L4 Cilium Network Policy between Istio Ingress and Pods with Envoy Proxy as Sidecar Container__

Altough Cilium provides L7 Network Policy, this scenario is going to demonstrate the using of L3/L4 Network Policy only, because Istio implements L7 too.

Previously you have to do:
- Install the Istio Ingress.
- Install the `02-ingress/hello-with-ingress.yaml`.
- Install the `03-ingress-sidecar/hello-v3-istio.yaml` (hello-v3 with Envoy Proxy injected as sidecar).

```sh
$ kubectl get pod -l istio=ingress --all-namespaces
$ kubectl apply -f 02-ingress/hello-with-ingress.yaml
$ kubectl apply -f 03-ingress-sidecar/hello-v3-istio.yaml

$ kubectl get pod,svc,ingress -n hello
```

Right now, the `hello-v3` with sidecar injected still is accesible from other container, the Ingress Route only redirects all traffic from Ingress Controller to the `hello-v3` pod.
Now, we are going to create a Network L3/L4 Policy (`04-ingress-sidecar-networkpolicy/hello-v3-netpol.yaml`) for `hello-v3` where traffic comming from Ingress Controller is allowed.
In other words, the `hello-v3` pod will accept incomming traffic from pod what matches the label `istio: ingress`.

Applying the policy for `hello-v3` pod.
```sh
$ kubectl apply -f 04-ingress-sidecar-networkpolicy/hello-v3-netpol.yaml
$ kubectl get networkpolicy -n hello
NAME                        POD-SELECTOR           AGE
hello-v3-netpol-ingress     app=hello,version=v3   27s
hello-v3-netpol-piggyback   app=hello,version=v3   27s
```
This policy allows incomming traffic from pod with labels `istio: ingress` and `run: radial-buxybox-curl` to pod with labels `app: hello` and `version: v3` over `5040` port.

Check the policies applied. You should see `Ingress Enabled Policy` for `hello-v3`.
```sh
$ export CILIUM_POD_NAME=$(kubectl get pods -l k8s-app=cilium -n kube-system -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec ${CILIUM_POD_NAME} -n kube-system -- cilium endpoint list
```

Now, test it by connecting from any pod without labels `istio: ingress` and `piggyback: ok`. For example, use `hello-v1` or `hello-v2` pod. It will not work.
```sh
$ kubectl get pod -n hello
NAME                               READY     STATUS    RESTARTS   AGE
hello-v1-69c9685b5-z82s6           1/1       Running   0          9m
hello-v2-54f5878c79-7xgmk          1/1       Running   0          9m
hello-v3-7cb4968687-zlkk2          2/2       Running   0          8m

$ kubectl exec hello-v1-69c9685b5-z82s6 -n hello -- curl -s hello-v3-svc-np:5040/hello
command terminated with exit code 6
```

But if you call `hello-v3` from pod with label `istio: ingress` it should work.
```sh
$ export ISTIO_INGRESS_POD_NAME=$(kubectl get pod -l istio=ingress -n istio-system -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec ${ISTIO_INGRESS_POD_NAME} -n istio-system -- curl -s hello-v3-svc-np.hello:5040/hello
oci runtime error: exec failed: container_linux.go:265: starting container process caused "exec: \"curl\": executable file not found in $PATH"

command terminated with exit code 126
```

Ops!, the problem is that `istio: ingress` pod don't have `curl` installed. Let's go to install it.
```sh
$ kubectl exec ${ISTIO_INGRESS_POD_NAME} -n istio-system -- apt-get -y update
$ kubectl exec ${ISTIO_INGRESS_POD_NAME} -n istio-system -- apt-get -y install curl
```
Now this should work.
```sh
$ kubectl exec ${ISTIO_INGRESS_POD_NAME} -n istio-system -- curl -s hello-v3-svc-np.hello:5040/hello
Hello version: v3, instance: hello-v3-7cb4968687-zlkk2

$ export ISTIO_INGRESS_PORT=$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
$ curl -s -H "Host: v3.helloworld.com" http://$(minikube ip):${ISTIO_INGRESS_PORT}/hello
Hello version: v3, instance: hello-v3-7cb4968687-zlkk2
```

We can install new pod with the label `piggyback: ok` which matches network policy `hello-v3-netpol.yaml` above created to call to `hello-v3`.
```sh
$ kubectl apply -f 04-ingress-sidecar-networkpolicy/hello-v3-piggyback.yaml
$ kubectl get pod -l piggyback=ok --all-namespaces
NAMESPACE   NAME                               READY     STATUS    RESTARTS   AGE
default     busybox-curl-745f8579cd-jw9q9      1/1       Running   2          22h
hello       hello-piggyback-557d5df6dc-4vsrx   1/1       Running   0          17m

$ kubectl exec busybox-curl-745f8579cd-jw9q9 -- curl -s hello-v3-svc-np.hello:5040/hello
Hello version: v3, instance: hello-v3-7cb4968687-zlkk2

$ kubectl exec hello-piggyback-557d5df6dc-4vsrx -n hello -- curl -s hello-v3-svc-np.hello:5040/hello
Hello version: v3, instance: hello-v3-7cb4968687-zlkk2
```

Let's debug this. Before we have to install Cilium Microscope (https://github.com/cilium/microscope), it will allow us view the logs:
```sh
$ kubectl apply -f 04-ingress-sidecar-networkpolicy/cilium/microscope.yaml
$ kubectl exec -it microscope -n kube-system -- sh
/usr/src/microscope #
/usr/src/microscope # microscope --from-selector istio=ingress
/usr/src/microscope # microscope --from-selector piggyback=ok
/usr/src/microscope # microscope --from-pod hello:hello-piggyback-557d5df6dc-4vsrx --to-pod hello:hello-v3-7cb4968687-zlkk2
```

## 3) More Demos: Istio Bookinfo App with L3/L4 Cilium Policy

Refs:
- Using Istio to Improve End-to-End Security: https://istio.io/blog/2017/0.1-auth.html
- Using Network Policy with Istio: https://istio.io/blog/2017/0.1-using-network-policy.html
- Consuming External Web Services -  Egress Rules for HTTPS traffic: https://istio.io/blog/2018/egress-https.html
- Consuming External TCP Services - Egress rules for TCP traffic: https://istio.io/blog/2018/egress-tcp.html
