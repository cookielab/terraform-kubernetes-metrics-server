variable "kubernetes_namespace" {
  type = string
  default = "kube-system"
  description = "Kubernetes namespace to deploy metrics server."
}

variable "kubernetes_resources_name_prefix" {
  type = string
  default = ""
  description = "Prefix for kubernetes resources name. For example `tf-module-`"
}

variable "kubernetes_resources_labels" {
  type = map(string)
  default = {}
  description = "Additional labels for kubernetes resources."
}

variable "kubernetes_deployment_node_selector" {
  type = map(string)
  default = {
    "beta.kubernetes.io/os" = "linux"
  }
  description = "Node selectors for kubernetes deployment"
}

variable "kubernetes_deployment_tolerations" {
  type = list(object({
    key = string
    operator = string
    value = string
    effect = string
  }))

  default = []
}

variable "kubernetes_priority_class_name" {
  type        = string
  default     = null
  description = "Priority class name for the kubernetes deployment"
}

variable "metrics_server_image" {
  type = string
  default = "k8s.gcr.io/metrics-server-amd64"
}

variable "metrics_server_image_tag" {
  type = string
  default = "v0.3.6"
}

variable "metrics_server_option_logtostderr" {
  type = bool
  default = true
  description = "Log to standard error instead of files in the container. You generally want this on."
}

variable "metrics_server_option_loglevel" {
  type = number
  default = 0
  description = "Set log verbosity. It's generally a good idea to run a log level 1 or 2 unless you're encountering errors. At log level 10, large amounts of diagnostic information will be reported, include API request and response bodies, and raw metric results from Kubelet."
}

variable "metrics_server_option_secure_port" {
  type = number
  default = 4443
  description = "Set the secure port. If you're not running as root, you'll want to set this to something other than the default."
}

variable "metrics_server_option_tls_cert_file" {
  type = string
  default = null
  description = "The serving certificate and key files. If not specified, self-signed certificates will be generated, but it's recommended that you use non-self-signed certificates in production."
}

variable "metrics_server_option_tls_private_key_file" {
  type = string
  default = null
  description = "The serving certificate and key files. If not specified, self-signed certificates will be generated, but it's recommended that you use non-self-signed certificates in production."
}

variable "metrics_server_option_kubelet_certificate_authority" {
  type = string
  default = null
  description = "The path of the CA certificate to use for validate the Kubelet's serving certificates."
}

variable "metrics_server_option_metric_resolution" {
  type = string
  default = "60s"
  description = "The interval at which metrics will be scraped from Kubelets in seconds."
}

variable "metrics_server_option_kubelet_insecure_tls" {
  type = bool
  default = false
  description = "Skip verifying Kubelet CA certificates. Not recommended for production usage, but can be useful in test clusters with self-signed Kubelet serving certificates."
}

variable "metrics_server_option_kubelet_port" {
  type = number
  default = 10250
  description = "The port to use to connect to the Kubelet (defaults to the default secure Kubelet port, 10250)."
}

variable "metrics_server_option_kubelet_preferred_address_types" {
  type = list(string)
  default = [
    "Hostname",
    "InternalDNS",
    "InternalIP",
    "ExternalDNS",
    "ExternalIP"
  ]
  description = "The order in which to consider different Kubelet node address types when connecting to Kubelet. Functions similarly to the flag of the same name on the API server."
}
