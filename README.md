# Civo terraform playground

Base terraform configuration to quickly deploy opinionated civo k3s cluster for experiments. Includes Longhorn for
persistence (not from marketplace!), Nginx as ingress controller, cert-manager with ACME issuer.

## Quickstart

### Create cluster

Go to https://www.civo.com/account/kubernetes and create a cluster:

- name `playground` (or whichever you like)
- 3 instances
- size `Medium`
- deselected `Traefic`

### Create `civo.auto.tfvars` file (optional)

Create file `civo.auto.tfvars` based on `civo.auto.tfvars.dist`

### Import cluster intro terraform

Run

```shell
terraform import civo_kubernetes_cluster.playground <Cluster ID>
```

### Apply

Run

```shell
terraform apply
```

## Known issues and limitations

- Can not create a cluster from terraform (waiting for https://github.com/civo/terraform-provider-civo)
- Cluster size (`3` nodes) and nodes type (`g3.medium` type) hardcoded for simplicity.
