resource "civo_kubernetes_cluster" "playground" {
  name              = "playground"
  applications      = "-traefik,metrics-server"
  num_target_nodes  = 3
  target_nodes_size = element(data.civo_instances_size.medium.sizes, 0).name
}
resource "local_file" "kubeconfig" {
  content  = civo_kubernetes_cluster.playground.kubeconfig
  filename = "${path.root}/.downloads/kubeconfig"
  depends_on = [
  civo_kubernetes_cluster.playground]
}

resource "civo_dns_domain_name" "main" {
  name = var.civo-domain
}
resource "civo_dns_domain_record" "www" {
  domain_id = civo_dns_domain_name.main.id
  type      = "CNAME"
  name      = "*.civo"
  value     = local.cluster-dns
  ttl       = 600
  depends_on = [
  civo_dns_domain_name.main]
}

//resource "helm_release" "nginx-ingress" {
//  name             = "nginx-ingress"
//  repository       = "https://charts.bitnami.com/bitnami"
//  chart            = "nginx-ingress-controller"
//  namespace        = "nginx-ingress-controller"
//  create_namespace = true
//
//  values = [
//    file("helm/values-nginx-ingress-controller.yaml")
//  ]
//  depends_on = [
//  civo_kubernetes_cluster.playground]
//}
//
resource "null_resource" "istio-operator" {
  provisioner "local-exec" {
    command = <<EOF
    set -xe
    mkdir -p ${path.root}/.downloads
    cd ${path.root}/.downloads

    rm -rf ./istio-${var.istio-version} || true
    curl -L https://git.io/getLatestIstio | ISTIO_VERSION=${var.istio-version} sh -
    rm -rf ./istio || true
    mv ./istio-${var.istio-version} ./istio
    EOF
  }
  provisioner "local-exec" {
    command = ".downloads/istio/bin/istioctl -c ${local_file.kubeconfig.filename} operator init"
  }
}

resource "kubernetes_namespace" "istio-namespace" {
  metadata {
    name = var.istio-namespace
  }
}

resource "kubectl_manifest" "istio" {
  count     = length(data.kubectl_path_documents.istio.documents)
  yaml_body = element(data.kubectl_path_documents.istio.documents, count.index)
  depends_on = [
    null_resource.istio-operator,
    kubernetes_namespace.istio-namespace
  ]
}

resource "null_resource" "istio-grafana" {
  triggers = {
    kubeconfig             = local_file.kubeconfig.filename
    istio-manifest-version = local.istio-manifest-version
  }
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${self.triggers.kubeconfig} apply -f https://raw.githubusercontent.com/istio/istio/release-${self.triggers.istio-manifest-version}/samples/addons/grafana.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig=${self.triggers.kubeconfig} delete -f https://raw.githubusercontent.com/istio/istio/release-${self.triggers.istio-manifest-version}/samples/addons/grafana.yaml"
  }
  depends_on = [
  kubectl_manifest.istio]
}

resource "null_resource" "istio-prometheus" {
  triggers = {
    kubeconfig             = local_file.kubeconfig.filename
    istio-manifest-version = local.istio-manifest-version
  }
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${self.triggers.kubeconfig} apply -f https://raw.githubusercontent.com/istio/istio/release-${self.triggers.istio-manifest-version}/samples/addons/prometheus.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig=${self.triggers.kubeconfig} delete -f https://raw.githubusercontent.com/istio/istio/release-${self.triggers.istio-manifest-version}/samples/addons/prometheus.yaml"
  }
  depends_on = [
  kubectl_manifest.istio]
}

resource "null_resource" "istio-kiali" {
  triggers = {
    kubeconfig             = local_file.kubeconfig.filename
    istio-manifest-version = local.istio-manifest-version
  }
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${self.triggers.kubeconfig} apply -f https://raw.githubusercontent.com/istio/istio/release-${self.triggers.istio-manifest-version}/samples/addons/kiali.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl --kubeconfig=${self.triggers.kubeconfig} delete -f https://raw.githubusercontent.com/istio/istio/release-${self.triggers.istio-manifest-version}/samples/addons/kiali.yaml"
  }
  depends_on = [
  kubectl_manifest.istio]
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

resource "kubernetes_namespace" "longhorn-system" {
  metadata {
    name = "longhorn-system"
    // Does not work with istio sidecars (yet?)
    //    labels = {
    //      istio-injection = "enabled"
    //    }
  }
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
    civo_kubernetes_cluster.playground,
    kubernetes_namespace.longhorn-system
  ]
}
