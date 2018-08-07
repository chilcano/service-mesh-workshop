# IAM, AuthN, AuthZ and RBAC on Amazon EKS

## 1. IAM in Kubernetes (AuthN)

- All Kubernetes clusters have two categories of users: service accounts managed by Kubernetes, and normal users.
- Normal Users (roger, osmond, g0123445, etc.)
  * Kubernetes does not have objects which represent normal user accounts. 
  * Normal users cannot be added to a cluster through an API call.
  * Kubernetes should be integrated with existing Identity Provider provided for the Cloud Provider or the Adhoc IAM: For example CoreOS DEX (Identity Service that uses OpenID Connect to drive authentication for other apps.) and CoreOS Tectonic (Multi Cloud Management System).
- Service Account (aws-node, kube-dns, etc.)
  * They are users managed by the Kubernetes API. They are bound to specific namespaces, and created automatically by the API server or manually through API calls. Service accounts are tied to a set of credentials stored as `Secrets`, which are mounted into pods allowing in-cluster processes to talk to the Kubernetes API.

## 2. RBAC (AuthZ)

- Since Kubernetes 1.6 Role Based Access Control (RBAC) is strongly recommended instead of using Attribute-based Access Control (ABAC).
- ABAC is a powerful concept. However, as implemented in Kubernetes, ABAC is difficult to manage and understand. It requires `ssh` and `root` filesystem access on the master VM of the cluster to make authorization policy changes. For permission changes to take effect the cluster API server must be restarted.
- RBAC permission policies are configured using `kubectl` or the Kubernetes API directly. Users can be authorized to make authorization policy changes using RBAC itself, making it possible to delegate resource management without giving away ssh access to the cluster master. RBAC policies map easily to the resources and operations used in the Kubernetes API.

__References:__

- https://stackoverflow.com/questions/42170380/how-to-add-users-to-kubernetes-kubectl 
- https://github.com/coreos/dex
- https://coreos.com/tectonic/docs/latest/users/tectonic-identity-overview.html
- https://kubernetes.io/blog/2017/04/rbac-support-in-kubernetes/
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/
- https://kubernetes.io/docs/reference/access-authn-authz/authorization/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/reference/access-authn-authz/abac/
- AWS EKS Workshop - AuthN & AuthZ: https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/04-path-security-and-networking/402-authentication-and-authorization

