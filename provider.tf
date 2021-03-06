provider "civo" {
  token = var.civo-token
}

provider "kubernetes" {
  host                   = local.cluster-server
  client_certificate     = local.user-client-certificate-data
  client_key             = local.user-client-key-data
  cluster_ca_certificate = local.cluster-certificate-authority-data
}

provider "helm" {
  kubernetes {
    host                   = local.cluster-server
    client_certificate     = local.user-client-certificate-data
    client_key             = local.user-client-key-data
    cluster_ca_certificate = local.cluster-certificate-authority-data
  }
}

provider "kubectl" {
  host                   = local.cluster-server
  client_certificate     = local.user-client-certificate-data
  client_key             = local.user-client-key-data
  cluster_ca_certificate = local.cluster-certificate-authority-data
}
