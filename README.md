# Terraform module for Kubernetes Metrics Server

> [!WARNING]  
> This module is no longer maintained. We recommend switching to [Helm](https://artifacthub.io/packages/helm/metrics-server/metrics-server).

This module deploys [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) to your Kubernetes cluster.

## Usage

```terraform
provider "kubernetes" {
  # your kubernetes provider config
}

module "metrics_server" {
  source = "cookielab/metrics-server/kubernetes"
  version = "0.9.0"
}
```
