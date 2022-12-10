terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
    container_name   = "tfstate"
  }
}

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    virtual_machine_scale_set {
      force_delete                 = true
      roll_instances_when_required = true
    }
  }
}

provider "azurerm" {
  alias           = "global"
  tenant_id       = var.global_tenant_id
  subscription_id = var.global_subscription_id
  client_id       = var.global_client_id
  client_secret   = var.global_client_secret

  features {}
}

provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}

provider "helm" {
  kubernetes {
    config_path = ".kube/config"
  }
}

provider "kubernetes" {
  config_path = ".kube/config"
}

provider "kubectl" {
  config_path = ".kube/config"
}
