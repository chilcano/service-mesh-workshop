# Routing API Traffic / Chaining APIs

## Install:

### 1) Standard:

```bash
$ cd service-mesh-workshop/labs/kube/05-routing-apis/
$ oc adm policy add-scc-to-user privileged -z test1-sa -n test1-ns
$ oc apply -f gis-test1.yaml
$ kubectl apply -f gis-test1.yaml
```

### 2) With Istio:

```bash
$ istioctl kube-inject -f gis-test1.yaml -o gis-test1-istio.yaml
$ kubectl apply -f gis-test1-istio.yaml
```

## Call to API:

### 1) Through ClusterIP SVC (SSH allways is needed):

```bash
$ export GW_URI_SVC_TEST1_AMBASSADOR=$(kubectl get svc test1-ambassador-svc -n test1-ns -o jsonpath='{.spec.clusterIP}'):$(kubectl get svc test1-ambassador-svc -n test1-ns -o jsonpath='{.spec.ports[0].port}')
$ minikube ssh -- curl -X POST -H "Content-Type: application/json" http://${GW_URI_SVC_TEST1_AMBASSADOR}/endpoint/payment-init/make-payment -d '\{\"fromSort\":\"20-32-00\",\"fromAccount\":\"10502211\",\"toSort\":\"20-32-66\",\"toAccount\":\"10502211\",\"amount\":4.89\}'

$ export GW_URI_SVC_TEST1=$(kubectl get svc test1-svc -n test1-ns -o jsonpath='{.spec.clusterIP}'):$(kubectl get svc test1-svc -n test1-ns -o jsonpath='{.spec.ports[0].port}')
$ minikube ssh -- curl -X POST -H "Content-Type: application/json" http://${GW_URI_SVC_TEST1}/endpoint/payment-init/make-payment -d '\{\"fromSort\":\"20-32-00\",\"fromAccount\":\"10502211\",\"toSort\":\"20-32-66\",\"toAccount\":\"10502211\",\"amount\":4.89\}'
```

### 2) Through Istio Ingress (External load balancers are not supported in Minikube. To use the host IP of the ingress service, along with the NodePort, to access the ingress.):

```bash
$ export ING_GW_URI=$(kubectl get po -l istio=ingress -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
$ curl -X POST -H "Content-Type: application/json" http://${ING_GW_URI}/endpoint/payment-init/make-payment -d '\{\"fromSort\":\"20-32-00\",\"fromAccount\":\"10502211\",\"toSort\":\"20-32-66\",\"toAccount\":\"10502211\",\"amount\":4.89\}'
$ curl -o /dev/null -s -w "%{http_code}\n" http://${ING_GW_URI}/endpoint/payment-init/make-payment -d '\{\"fromSort\":\"20-32-00\",\"fromAccount\":\"10502211\",\"toSort\":\"20-32-66\",\"toAccount\":\"10502211\",\"amount\":4.89\}'
```
