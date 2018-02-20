# Weawing a Service Mesh

## References:
* https://istio.io/docs/guides/bookinfo.html
* https://github.com/istio/istio/tree/master/samples/bookinfo
* http://kubernetesbyexample.com

## Tested with:
- Minishift v1.11.0+4459917
- Kubernetes 3.7
- istio 0.5.0
- VirtualBox 5.1.30
- macOS High Sierra, version 10.13.2 (17C88)

## 1. Installation Istio and Addons

```bash
$ wget https://github.com/istio/istio/releases/download/0.5.0/istio-0.5.0-linux.tar.gz  ## or istio-0.5.0-osx.tar.gz
$ tar -xzf istio-0.5.0-linux.tar.gz   ## or istio-0.5.0-osx.tar.gz
$ oc login -u system:admin --server 192.168.99.100:8443 --insecure-skip-tls-verify
$ cd istio-0.5.0
$ ./install-istio.sh
```
Checking installation:
```bash
$ oc get all -n istio-system

## Openshift Console:
https://<openshift-host-name>:8443/console

## Istio Addons URLs:
http://zipkin-istio-system.<public-ip>.nip.io/zipkin/
http://grafana-istio-system.<public-ip>.nip.io/dashboard/db/istio-dashboard
http://servicegraph-istio-system.<public-ip>.nip.io/dotviz
```

## 2. Installation BookInfo sample app

```bash
$ oc new-project bookinfo
## you can use this script ./install-istio-sample-app.sh
$ oc apply -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo.yaml)
```

Checking installation:
```bash
$ oc get all -n bookinfo
```
Entry point:
```bash
http://istio-ingress-istio-system.<public-ip>.nip.io/productpage
```

## 3. Useful commands

```bash
### get Deployments
$ oc get deploy -n istio-system

### get Pods
$ oc get pods -n istio-system

### get Services
$ oc get svc -n istio-system

### get Routes
$ oc get routes -n istio-system

### show logs
$ oc logs <pod> -c <container> -n <namespace>

### get ssh remote access to container
$ oc rsh <pod> -c <container> -n <namespace> -- <linux-command>

### execute commands in container
$ oc exec <pod> -c <container> -n <namespace> -- <linux-command>
```

### Observations BookInfo:
* `oc rsh <pod>  -c <container> -n <namespace> -- <command>` doesn't work because this Pod/Container has not shell.
* `oc logs <pod> -c <container> -n <namespace>` doesn't shown logs because this Pod/Container doesn't send logs to stdout.
* `oc exec <pod> -c <container> -n <namespace> -- iptables -t nat -L` doesn't work because you need `root` permissions.
