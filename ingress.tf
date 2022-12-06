locals {
  ingress_nginx_namespace = "ingress-nginx"
  cert_manager_namespace  = "cert-manager"
  external_dns_namespace  = "external-dns"
  namespaces = toset([
    local.ingress_nginx_namespace,
    local.cert_manager_namespace,
    local.external_dns_namespace
  ])
}

resource "random_pet" "cert_manager" {
  length    = 2
  separator = "."
}

resource "azurerm_public_ip" "ingress" {
  name                 = "pip-${local.resource_suffix}-ing"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  allocation_method    = "Static"
  sku                  = "Standard"
  zones                = local.zones
  ddos_protection_mode = var.ddos_protection_mode_enabled ? "Enabled" : "Disabled"
}

resource "kubernetes_namespace_v1" "main" {
  for_each = local.namespaces

  metadata {
    name = each.value
  }

  depends_on = [
    local_file.kube_config
  ]
}

resource "helm_release" "ingress_nginx" {
  name            = "ingress-nginx"
  repository      = "https://kubernetes.github.io/ingress-nginx"
  chart           = "ingress-nginx"
  namespace       = local.ingress_nginx_namespace
  cleanup_on_fail = true
  atomic          = true
  wait            = true

  values = [
    templatefile("./k8s/nginx.values.yaml",
      {
        load_balancer_ip             = azurerm_public_ip.ingress.ip_address,
        load_balancer_resource_group = azurerm_resource_group.main.name
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.main,
    azurerm_public_ip.ingress,
  ]
}

resource "helm_release" "external_dns" {
  name            = "external-dns"
  repository      = "https://kubernetes-sigs.github.io/external-dns"
  chart           = "external-dns"
  namespace       = local.external_dns_namespace
  cleanup_on_fail = true
  atomic          = true
  wait            = true

  set {
    name  = "secretConfiguration.enabled"
    value = true
  }

  set {
    name  = "secretConfiguration.mountPath"
    value = true
  }

  set {
    name  = "secretConfiguration.data"
    value = <<EOF
    {
      "tenantId": "${var.global_tenant_id}",
      "subscriptionId": "${var.global_subscription_id}",
      "resourceGroup": "${var.global_resource_group_name}",
      "useManagedIdentityExtension": true,
      "userAssignedIdentityID": "${azurerm_kubernetes_cluster.main.kubelet_identity.0.client_id}"
    }
    EOF
  }

  depends_on = [
    kubernetes_namespace_v1.main,
    azurerm_role_assignment.kubelet_dns_zone_contributor
  ]
}

resource "helm_release" "cert_manager" {
  name            = "cert-manager"
  repository      = "https://charts.jetstack.io/cert-manager"
  chart           = "cert-manager"
  namespace       = local.cert_manager_namespace
  cleanup_on_fail = true
  atomic          = true
  wait            = true

  set {
    name  = "installCRDs"
    value = true
  }

  depends_on = [
    kubernetes_namespace_v1.main,
    azurerm_role_assignment.kubelet_dns_zone_contributor
  ]
}

resource "kubernetes_manifest" "cert_manager_cluster_issuer" {
  manifest = templatefile("./k8s/cert-manager.yaml", {
    email                      = "${lower(random_pet.cert_manager.id)}@${var.global_dns_zone_name}"
    subscription_id            = var.global_subscription_id
    resource_group_name        = var.global_resource_group_name
    hosted_zone_name           = var.global_dns_zone_name
    managed_identity_client_id = azurerm_kubernetes_cluster.main.kubelet_identity.0.client_id
  })

  depends_on = [
    kubernetes_namespace_v1.main
  ]
}
