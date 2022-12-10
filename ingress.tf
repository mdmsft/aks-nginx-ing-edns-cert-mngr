locals {
  ingress_nginx_namespace = "ingress-nginx"
  cert_manager_namespace  = "cert-manager"
  external_dns_namespace  = "external-dns"
  cluster_issuer          = "default"
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

# resource "kubernetes_namespace_v1" "main" {
#   for_each = local.namespaces

#   metadata {
#     name = each.value
#   }

#   depends_on = [
#     local_file.kube_config
#   ]
# }

# resource "helm_release" "ingress_nginx" {
#   name            = "ingress-nginx"
#   repository      = "https://kubernetes.github.io/ingress-nginx"
#   chart           = "ingress-nginx"
#   namespace       = local.ingress_nginx_namespace
#   cleanup_on_fail = true
#   atomic          = true
#   wait            = true

#   values = [
#     templatefile("./k8s/nginx.values.yaml",
#       {
#         load_balancer_ip             = azurerm_public_ip.ingress.ip_address,
#         load_balancer_resource_group = azurerm_public_ip.ingress.resource_group_name,
#         public_ip_name               = azurerm_public_ip.ingress.name
#     })
#   ]

#   depends_on = [
#     kubernetes_namespace_v1.main,
#     azurerm_public_ip.ingress,
#     azurerm_role_assignment.cluster_network_contributor_ip_address
#   ]
# }

# resource "helm_release" "external_dns" {
#   name            = "external-dns"
#   repository      = "https://kubernetes-sigs.github.io/external-dns"
#   chart           = "external-dns"
#   namespace       = local.external_dns_namespace
#   cleanup_on_fail = true
#   atomic          = true
#   wait            = true
#   recreate_pods   = true
#   timeout         = 60

#   values = [
#     templatefile("./k8s/external-dns.yaml", {
#       data = jsonencode({
#         tenantId                    = var.global_tenant_id
#         subscriptionId              = var.global_subscription_id
#         resourceGroup               = var.global_resource_group_name
#         useManagedIdentityExtension = true
#         userAssignedIdentityID      = azurerm_kubernetes_cluster.main.kubelet_identity.0.client_id
#       })
#     })
#   ]

#   depends_on = [
#     kubernetes_namespace_v1.main,
#     azurerm_role_assignment.kubelet_dns_zone_contributor
#   ]
# }

# resource "helm_release" "cert_manager" {
#   name            = "cert-manager"
#   repository      = "https://charts.jetstack.io"
#   chart           = "cert-manager"
#   namespace       = local.cert_manager_namespace
#   cleanup_on_fail = true
#   atomic          = true
#   wait            = true

#   set {
#     name  = "installCRDs"
#     value = true
#   }

#   depends_on = [
#     kubernetes_namespace_v1.main,
#     azurerm_role_assignment.kubelet_dns_zone_contributor
#   ]
# }

# resource "kubectl_manifest" "cert_manager_cluster_issuer" {
#   yaml_body = templatefile("./k8s/cert-manager.yaml", {
#     name                       = local.cluster_issuer
#     email                      = "${lower(random_pet.cert_manager.id)}@${var.global_dns_zone_name}"
#     subscription_id            = var.global_subscription_id
#     resource_group_name        = var.global_resource_group_name
#     hosted_zone_name           = var.global_dns_zone_name
#     managed_identity_client_id = azurerm_kubernetes_cluster.main.kubelet_identity.0.client_id
#   })

#   depends_on = [
#     helm_release.cert_manager
#   ]
# }

# resource "kubectl_manifest" "container_log" {
#   yaml_body = file("./k8s/container-log-v2.yaml")

#   depends_on = [
#     local_file.kube_config
#   ]
# }

# resource "helm_release" "echo" {
#   name             = "echo"
#   chart            = "./helm"
#   namespace        = "echo"
#   create_namespace = true
#   cleanup_on_fail  = true
#   atomic           = true
#   wait             = true

#   values = [
#     templatefile("./k8s/echo.values.yaml", {
#       replicas            = var.echo_replicas
#       image               = var.echo_image
#       cpu_limit           = var.echo_cpu_limit
#       memory_limit        = var.echo_memory_limit
#       liveness_probe_path = var.echo_liveness_probe_path
#       port                = var.echo_port
#       run_as_user         = var.echo_run_as_user
#       run_as_group        = var.echo_run_as_group
#       cluster_issuer      = local.cluster_issuer
#       domain              = var.global_dns_zone_name
#     })
#   ]

#   depends_on = [
#     local_file.kube_config,
#     helm_release.cert_manager,
#     helm_release.external_dns,
#     helm_release.ingress_nginx
#   ]

#   timeout = 60
# }
