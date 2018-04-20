# Traffic Management with Ingress, Sidecar and Network Policy

__Kubernetes' Primitives used:__

* Deployment
* Pods
* Services
* Ingress Resources
* Ingress Controller
* Init Container and Sidecar Container
* Network Policy

## 1) Towards the end-to-end security

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
- Create a Network L3/L4 Policy (`04-ingress-sidecar-networkpolicy/hello-v3-netpol.yaml`) for `04-ingress-sidecar-networkpolicy/hello-v3-istio.yaml` and install it.

```yaml
$ cat 04-ingress-sidecar-networkpolicy/hello-v3-netpol.yaml
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
$ kubectl apply -f 04-ingress-sidecar-networkpolicy/hello-v3-netpol.yaml
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

## 3) More Demos: Istio Bookinfo App with L3/L4 Cilium Policy

Refs:
- Using Istio to Improve End-to-End Security: https://istio.io/blog/2017/0.1-auth.html
- Using Network Policy with Istio: https://istio.io/blog/2017/0.1-using-network-policy.html
- Consuming External Web Services -  Egress Rules for HTTPS traffic: https://istio.io/blog/2018/egress-https.html
- Consuming External TCP Services - Egress rules for TCP traffic: https://istio.io/blog/2018/egress-tcp.html
