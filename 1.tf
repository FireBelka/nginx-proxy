terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "nginx-proxy"
  location = "eastus"
}

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "nginx-proxy-sp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "demo" {
  name                = "nginx-proxy-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
  site_config {
    linux_fx_version = "COMPOSE|${filebase64("docker-compose.yml")}"
  }
  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "...",
    "DOCKER_REGISTRY_SERVER_USERNAME" = "...",
    "DOCKER_REGISTRY_SERVER_PASSWORD" = "...",
  }
}

#data "azurerm_resource_group" "acr-group" {
#  name = "K8s-test"
#}
#data "azurerm_container_registry" "acr" {
#  name = "testRegK8s"
#}

#resource "azurerm_container_registry_webhook" "webhook" {
#  name                = "nginx-web-app-webhook"
#  resource_group_name = azurerm_resource_group.acr-group.name
#  registry_name       = azurerm_container_registry.acr.name
#  location            = azurerm_resource_group.acr-group.location
#
#  service_uri = "https://mywebhookreceiver.example/mytag"
#  status      = "enabled"
#  scope       = "mytag:*"
#  actions     = ["push"]
#  custom_headers = {
#    "Content-Type" = "application/json"
#  }
#}
