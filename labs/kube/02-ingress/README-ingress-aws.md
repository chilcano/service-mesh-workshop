# Redirecting the API traffic through the Ingress Controller

## 1) Install an Ingress Controller on AWS:

## 2) Routing the API traffic:

```bash
$ kubectl apply -f service-mesh-workshop/labs/kube/02-ingress/echoserver-app.yaml
$ export ECHO_SERVER=$(kubectl get svc echo-svc-ci -n echoserver-ns -o jsonpath='{.spec.clusterIP}'):$(kubectl get svc echo-svc-ci -n echoserver-ns -o jsonpath='{.spec.ports[0].port}')
$ export DATA_JSON='{"fromSort":"20-32-00"\,"fromAccount":"10502211"\,"toSort":"20-32-66"\,"toAccount":"10502211"\,"amount":4.89}'
$ minikube ssh -- curl -H "Content-Type:application/json" -d ${DATA_JSON} http://${ECHO_SERVER}/test?key=val -v
```
