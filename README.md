# terraform-aws-eks

## Description
This repo contains an AWS EKS configuration. It will setup Vpc, security groups, load balancer, eks cluster with worker nodes.
This can be deploy with standard Terraform Commands:
```bash
terraform init
terraform plan 
terraform apply

```

It should take around 10 minutes to bring up the full cluster. Once the configuration is deployed successfully, You need to setup Kubectl and AWS IAM Authenticator for connecting to the cluster.
To install `kubectl` the easiest way again is to use `homebrew` on macOS.
```bash
brew install kubernetes-cli

```
To install AWS IAM authenticator
```bash
go get -u github.com/kubernetes-sigs/aws-iam-authenticator

```

Before we can use the cluster we need to output both the `kubeconfig` and the `aws-auth` configmap which will allow our nodes to connect to the cluster.
```bash
terraform output kubeconfig > kubeconfig

```
Next we will use the same `output` subcommand to output the `aws-auth` configmap which will give the worker nodes the ability to connect to the cluster.
```bash
terraform output config-map-aws-auth > aws-auth.yaml

```
# Connecting to your EKS Cluster
Now that we have all the files in-place we can then `export` out `kubeconfig` path and try using `kubectl`.
```bash
export KUBECONFIG=kubeconfig

```
Now we can check the connection to the Amazon EKS cluster but running `kubectl`.
```bash
kubectl get all
....
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
service/kubernetes ClusterIP 10.100.0.1 <none> 443/TCP 10m
....
```

With this working we can then `apply` the `aws-auth` configmap.
```bash
kubectl apply -f aws-auth.yaml
....
configmap/aws-auth created
....
```
Now if we go an list `nodes` we should see that we have a full cluster up and running and ready to use!
```bash
kubectl get nodes
...
NAME                                       STATUS   ROLES    AGE    VERSION
ip-10-0-0-123.us-west-2.compute.internal   Ready    <none>   105s   v1.13.7-eks-c57ff8
ip-10-0-1-154.us-west-2.compute.internal   Ready    <none>   106s   v1.13.7-eks-c57ff8
...
```

# Launch a Guest Book Application:
For more information about setting up the guest book example, see https://github.com/kubernetes/examples/blob/master/guestbook-go/README.md in the Kubernetes documentation.
Or Follow the steps from here.
