resource "civo_kubernetes_cluster" "playground" {
  name              = "playground"
  applications      = "-traefik,metrics-server"
  num_target_nodes  = 3
  target_nodes_size = element(data.civo_instances_size.medium.sizes, 0).name
}

resource "civo_dns_domain_name" "main" {
  name = var.civo-domain
}
resource "civo_dns_domain_record" "www" {
  domain_id  = civo_dns_domain_name.main.id
  type       = "CNAME"
  name       = "*.civo"
  value      = local.cluster-dns
  ttl        = 600
  depends_on = [civo_dns_domain_name.main]
}

resource "helm_release" "nginx-ingress" {
  name             = "nginx-ingress"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "nginx-ingress-controller"
  namespace        = "nginx-ingress-controller"
  create_namespace = true

  values = [
    file("helm/values-nginx-ingress-controller.yaml")
  ]
  depends_on = [
  civo_kubernetes_cluster.playground]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    file("helm/values-cert-manager.yaml")
  ]
  depends_on = [
  civo_kubernetes_cluster.playground]
}

resource "kubectl_manifest" "production-issuer" {
  count     = length(data.kubectl_path_documents.production-issuer.documents)
  yaml_body = element(data.kubectl_path_documents.production-issuer.documents, count.index)
  depends_on = [
    helm_release.cert-manager
  ]
}

resource "kubectl_manifest" "staging-issuer" {
  count     = length(data.kubectl_path_documents.staging-issuer.documents)
  yaml_body = element(data.kubectl_path_documents.staging-issuer.documents, count.index)
  depends_on = [
    helm_release.cert-manager
  ]
}

resource "helm_release" "longhorn" {
  provider         = helm
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  namespace        = "longhorn-system"
  create_namespace = true

  values = [
    file("helm/values-longhorn.yaml")
  ]
  set {
    name  = "ingress.host"
    value = "longhorn.civo.${var.civo-domain}"
  }
  depends_on = [
  civo_kubernetes_cluster.playground]
}
