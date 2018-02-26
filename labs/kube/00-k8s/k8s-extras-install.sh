#!/usr/bin/env bash

VM_NAME=${1:-kube0}
WEAVE_SCOPE_VERSION=${2:-v1.7.3}     # use 'latest' for latest version

minikube profile ${VM_NAME}
minikube addons enable heapster
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?v=${WEAVE_SCOPE_VERSION}&k8s-service-type=NodePort&k8s-version=$(kubectl version | base64 | tr -d '\n')"

cat << EOF
...wait for a few seconds before to open:
- Heapster:    $ minikube addons open heapster
- Dashboard:   $ minikube dashboard
- WeaveScope:  $ open http://$(minikube ip):$(kubectl get svc/weave-scope-app -n weave -o jsonpath='{.spec.ports[0].nodePort}')
EOF
