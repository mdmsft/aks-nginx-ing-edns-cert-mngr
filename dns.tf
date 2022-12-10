resource "azurerm_role_assignment" "kubelet_dns_zone_contributor" {
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
  scope                = data.azurerm_dns_zone.global.id
}
