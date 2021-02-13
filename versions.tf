terraform {
  required_providers {
    civo = {
      source = "civo/civo"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    helm = {
      source = "hashicorp/helm"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
