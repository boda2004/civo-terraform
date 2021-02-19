variable "civo-token" {}
variable "acme-issuer-email" {}
variable "civo-domain" {}
variable "istio-version" {
  default = "1.9.0"
}
variable "istio-namespace" {
  default = "istio-system"
}

variable "istio-name" {
  default = "example-istiocontrolplane"
}

variable "istio-profile" {
  default = "demo"
}
