data "civo_instances_size" "medium" {
  filter {
    key = "name"
    values = [
    "g3.k3s.medium"]
  }
}

locals {
  cluster-dns                        = civo_kubernetes_cluster.playground.dns_entry
  kubeconfig                         = yamldecode(civo_kubernetes_cluster.playground.kubeconfig)
  cluster-server                     = local.kubeconfig.clusters[0].cluster.server
  cluster-certificate-authority-data = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
  user-client-certificate-data       = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
  user-client-key-data               = base64decode(local.kubeconfig.users[0].user.client-key-data)
  istio-manifest-version             = join(".", slice(split(".", var.istio-version), 0, 2))
}

data "kubectl_path_documents" "production-issuer" {
  pattern = "./manifest/production-issuer.yaml"
  vars = {
    acme-issuer-email = var.acme-issuer-email
  }
}

data "kubectl_path_documents" "staging-issuer" {
  pattern = "./manifest/staging-issuer.yaml"
  vars = {
    acme-issuer-email = var.acme-issuer-email
  }
}

data "kubectl_path_documents" "istio" {
  pattern = "./manifest/istio.yaml"
  vars = {
    istio-profile   = var.istio-profile
    istio-name      = var.istio-name
    istio-namespace = var.istio-namespace
  }
}
