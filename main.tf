locals {
  kubernetes_resources_labels = merge(
    {
      "cookielab.io/terraform-module" = "metrics-server",
    }, var.kubernetes_resources_labels)
  cluster_role_labels = merge(
    {
      "cookielab.io/terraform-module" = "metrics-server",
    },
    var.kubernetes_resources_labels,
    {
      "rbac.authorization.k8s.io/aggregate-to-view" = "true",
      "rbac.authorization.k8s.io/aggregate-to-edit" = "true",
      "rbac.authorization.k8s.io/aggregate-to-admin" = "true"
    }
  )
  deployment_selector_labels = {
    "cookielab.io/application" = "metrics-server",
    "cookielab.io/process" = "bootstrap"
  }
  deployment_labels = merge(
    {
      "cookielab.io/terraform-module" = "metrics-server",
    },
    var.kubernetes_resources_labels,
    {
      "cookielab.io/application" = "metrics-server",
      "cookielab.io/process" = "bootstrap"
    }
  )
  service_labels = merge(
    {
      "cookielab.io/terraform-module" = "metrics-server",
    },
    var.kubernetes_resources_labels,
    {
      "kubernetes.io/name" = "Metrics-server"
      "kubernetes.io/cluster-service" = "true"
    }
  )
  port_name = "main-port"
  deployment_arguments = concat(
    [
      "--cert-dir=/tmp"
    ],
    var.metrics_server_option_logtostderr == true ? [
      "--logtostderr"
    ] : [],
    [
      "--v=${var.metrics_server_option_loglevel}"
    ],
    [
      "--secure-port=${var.metrics_server_option_secure_port}"
    ],
    var.metrics_server_option_tls_cert_file != null ? [
      "--tls-cert-file=${var.metrics_server_option_tls_cert_file}"
    ] : [],
    var.metrics_server_option_tls_private_key_file != null ? [
      "--tls-private-key-file=${var.metrics_server_option_tls_private_key_file}"
    ] : [],
    var.metrics_server_option_kubelet_certificate_authority != null ? [
      "--kubelet-certificate-authority=${var.metrics_server_option_kubelet_certificate_authority}"
    ] : [],
    [
      "--metric-resolution=${var.metrics_server_option_metric_resolution}"
    ],
    var.metrics_server_option_kubelet_insecure_tls == true ? [
      "--kubelet-insecure-tls"
    ] : [],
    [
      "--kubelet-port=${var.metrics_server_option_kubelet_port}"
    ],
    [
      "--kubelet-preferred-address-types=${join(",", var.metrics_server_option_kubelet_preferred_address_types)}"
    ]
  )
}

resource "kubernetes_service_account" "metrics_server" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}metrics-server"
    namespace = var.kubernetes_namespace
  }
}

resource "kubernetes_cluster_role" "metrics_server" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}system:metrics-server"
    labels = local.kubernetes_resources_labels
  }

  rule {
    api_groups = [""]
    resources = ["pods", "nodes", "nodes/stats", "namespaces"]
    verbs = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "metrics_server_auth_delegator" {
  metadata {
    name = kubernetes_cluster_role.metrics_server.metadata.0.name
    labels = local.kubernetes_resources_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = kubernetes_cluster_role.metrics_server.metadata.0.name
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.metrics_server.metadata.0.name
    namespace = kubernetes_service_account.metrics_server.metadata.0.namespace
  }
}

resource "kubernetes_cluster_role" "metrics_server_aggregated_metrics_reader" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}system:aggregated-metrics-reader"
    labels = local.cluster_role_labels
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources = ["pods", "nodes"]
    verbs = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "metrics_server_aggregated_metrics_reader" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}metrics-server:system:auth-delegator"
    labels = local.kubernetes_resources_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "system:auth-delegator" # predefined cluster role
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.metrics_server.metadata.0.name
    namespace = kubernetes_service_account.metrics_server.metadata.0.namespace
  }
}

resource "kubernetes_role_binding" "metrics_server_auth_reader" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}metrics-server-auth-reader"
    namespace = var.kubernetes_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "extension-apiserver-authentication-reader" # predefined role
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.metrics_server.metadata.0.name
    namespace = kubernetes_service_account.metrics_server.metadata.0.namespace
  }
}

resource "kubernetes_api_service" "metrics_server" {
  metadata {
    name = "v1beta1.metrics.k8s.io"
  }
  spec {
    service {
      name = "metrics-server"
      namespace = var.kubernetes_namespace
    }

    group = "metrics.k8s.io"
    version = "v1beta1"
    insecure_skip_tls_verify = true
    group_priority_minimum = 100
    version_priority = 100
  }

  lifecycle {
    ignore_changes = [
      spec[0].service[0].port,
    ]
  }
}

resource "kubernetes_deployment" "metrics_server" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}metrics-server"
    namespace = var.kubernetes_namespace

    labels = local.deployment_labels
  }

  spec {
    selector {
      match_labels = local.deployment_selector_labels
    }

    template {
      metadata {
        name = "${var.kubernetes_resources_name_prefix}metrics-server"
        labels = local.deployment_labels
      }

      spec {
        service_account_name = kubernetes_service_account.metrics_server.metadata.0.name
        automount_service_account_token = true

        priority_class_name = var.kubernetes_priority_class_name

        container {
          name = "metrics-server"
          image = "${var.metrics_server_image}:${var.metrics_server_image_tag}"

          args = local.deployment_arguments

          port {
            name = local.port_name
            container_port = var.metrics_server_option_secure_port
            protocol = "TCP"
          }

          security_context {
            read_only_root_filesystem = true
            run_as_non_root = true
            run_as_user = 1000
          }

          image_pull_policy = "Always"

          volume_mount {
            name = "tmp-dir"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp-dir"
          empty_dir {

          }
        }

        node_selector = var.kubernetes_deployment_node_selector

        dynamic toleration {
          for_each = var.kubernetes_deployment_tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = toleration.value.value
            effect   = toleration.value.effect
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "metrics_server" {
  metadata {
    name = "${var.kubernetes_resources_name_prefix}metrics-server"
    namespace = var.kubernetes_namespace

    labels = local.service_labels
  }

  spec {
    selector = local.deployment_selector_labels

    port {
      port = 443
      protocol = "TCP"
      target_port = local.port_name
    }
  }
}
