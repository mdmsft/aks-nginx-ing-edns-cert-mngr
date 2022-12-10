data "azurerm_client_config" "main" {}

data "azuread_client_config" "main" {}

data "azurerm_kubernetes_service_versions" "main" {
  location        = var.location
  include_preview = var.kubernetes_service_versions_include_preview
}

data "azurerm_resource_group" "global" {
  provider = azurerm.global
  name     = var.global_resource_group_name
}

data "azurerm_dns_zone" "global" {
  provider            = azurerm.global
  name                = var.global_dns_zone_name
  resource_group_name = data.azurerm_resource_group.global.name
}
