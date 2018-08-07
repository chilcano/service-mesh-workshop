# Network Segmentation and Isolation with Kubernetes Network Policy

TBC

- Kubernetes Network Policy objects allow for fine-grained network policy enforcement, ensuring that traffic within your Kubernetes cluster can only flow in the direction that you specify. As an example, if we take a scenario where Kubernetes namespaces are used to enforce boundaries between products, or even enforce boundaries between different environments (e.g. development vs production), network policies can be configured to ensure no unauthorized network traffic is allowed beyond its boundary. Think of it as being similar to applying Iptables filters in the AWS world.
- Network policies are implemented by an add-on; there are several available. Any of these solutions allow you to specify a network policy and then enforce the rules while your services are running.
* Calico
* Weave Net

__References:__

- AWS EKS Workshop:
  * Network Policy: https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/04-path-security-and-networking/404-network-policies
  * Set up a Kubernetes cluster with Calico: https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/04-path-security-and-networking/404-network-policies/calico
  * Set up a Kubernetes cluster with Weave Net: https://github.com/aws-samples/aws-workshop-for-kubernetes/tree/master/04-path-security-and-networking/404-network-policies/weavenet

