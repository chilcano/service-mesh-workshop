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

### 1) Through ClusterIP SVC and remotely

```bash
$ export GW_URI_SVC_TEST1_AMBASSADOR=$(kubectl get svc test1-ambassador-svc -n test1-ns -o jsonpath='{.spec.clusterIP}'):$(kubectl get svc test1-ambassador-svc -n test1-ns -o jsonpath='{.spec.ports[0].port}')

$ echo $GW_URI_SVC_TEST1_AMBASSADOR
10.97.182.5:6000
```

```bash
$ minikube ssh

$ curl -H "Content-Type:application/json" -d '{"fromSort":"20-32-00","fromAccount":"10502211","toSort":"20-32-66","toAccount":"10502211","amount":4.89}' http://10.97.182.5:6000/endpoint/payment-init/make-payment -v

> POST /endpoint/payment-init/make-payment HTTP/1.1
> Host: 10.97.182.5:6000
> User-Agent: curl/7.57.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 105
>
< HTTP/1.1 200
< X-Application-Context: application:80
< x-ossie-test: applied in security module
< x-ossie-test2: applied in security module
< x-ossie-test3: applied in security module
< Date: Fri, 02 Mar 2018 13:59:59 GMT
< Content-Type: application/json;charset=UTF-8
< Transfer-Encoding: chunked
<
{"data":{"paymentResponse":{"paymentId":"b53bf1e0-1e63-495e-96ab-4c22ef220887","toSort":"20-32-66","toAccount":"10502211","amount":4.89,"paymentMade":true}},"errors":null,"meta":{},"jsonapi":null,"links":null}
```

### 2) Through ClusterIP SVC and copying the json payload to VM

```bash
$ minikube ssh

$ cat <<EOF > data_remote.json
{
  "fromSort": "20-32-00",
  "fromAccount": "10502211",
  "toSort": "20-32-66",
  "toAccount": "10502211",
  "amount":4.89
}
EOF

$ exit

$ minikube ssh -- cat data_remote.json

$ minikube ssh -- curl -H "Content-Type:application/json" -d @data_remote.json http://${GW_URI_SVC_TEST1_AMBASSADOR}/endpoint/payment-init/make-payment -v
```

### 3) Through ClusterIP SVC and defining the json payload as variable

```bash
$ export DATA_JSON=$(cat <<EOF
{
  "fromSort": "20-32-00",
  "fromAccount": "10502211",
  "toSort": "20-32-66",
  "toAccount": "10502211",
  "amount": 4.89
}
EOF
)

$ echo $DATA_JSON | minikube ssh 'bash -c "cat >> data_remote2.json"'    ## Ctrl+D or Ctrl+C to send end signal

$ minikube ssh -- curl -H "Content-Type:application/json" -d @data_remote2.json http://${GW_URI_SVC_TEST1_AMBASSADOR}/endpoint/payment-init/make-payment -v
```

### 4) Through Istio Ingress (External load balancers are not supported in Minikube. To use the host IP of the ingress service, along with the NodePort, to access the ingress.):

```bash
$ export ING_GW_URI=$(kubectl get po -l istio=ingress -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
$ curl -X POST -H "Content-Type: application/json" -d '{"fromSort":"20-32-00","fromAccount":"10502211","toSort":"20-32-66","toAccount":"10502211","amount":4.89}' http://${ING_GW_URI}/endpoint/payment-init/make-payment
$ curl -o /dev/null -s -w "%{http_code}\n" -d '{"fromSort":"20-32-00","fromAccount":"10502211","toSort":"20-32-66","toAccount":"10502211","amount":4.89}' http://${ING_GW_URI}/endpoint/payment-init/make-payment
```
