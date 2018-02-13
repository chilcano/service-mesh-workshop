# 4. Install nginx-ingress (AWS EC2):

## Refs:
```
  - https://github.com/kubernetes/ingress-nginx/tree/master/deploy#aws
  - http://containerops.org/2017/01/30/kubernetes-services-and-ingress-under-x-ray
```

## Mandatory commands:
```
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/namespace.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/default-backend.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/configmap.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/tcp-services-configmap.yaml | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/udp-services-configmap.yaml | kubectl apply -f -
```
## Install without RBAC roles:
```
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/without-rbac.yaml | kubectl apply -f -
```
## Patch ingress-nginx:
```
kubectl patch deployment -n ingress-nginx nginx-ingress-controller --type='json' --patch="$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/publish-service-patch.yaml)"
```
## L4:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/aws/service-l4.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/aws/patch-configmap-l4.yaml
```
## L7:
```
#kubectl apply -f provider/aws/service-l7.yaml
kubectl apply -f ~/1github-repo/ansible-minishift-istio-security/kube/samples/helloworld/nginx-ingress/aws/service-l7.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/aws/patch-configmap-l7.yaml
```
## Patch the svc without RBAC :
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/patch-service-without-rbac.yaml
```
