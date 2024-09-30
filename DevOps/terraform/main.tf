terraform {
  required_providers {

    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }

  backend "azurerm" {

  }

}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_api_management" "az_api_mng_svc" {
  name                = "${var.environment}-az-api-svc-mng-ops"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = "Example Publisher"
  publisher_email     = "nhat.thaiquang@asnet.com.vn"
  sku_name            = "Standard_1"
  tags = {
    Environment = var.environment
  }
  policy {
    xml_content = <<XML
    <policies>
      <inbound />
      <backend />
      <outbound />
      <on-error />
    </policies>
XML
  }
}

resource "azurerm_api_management_api" "api" {
  name                = "${var.environment}-api"
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  revision            = "1"
  display_name        = "${var.environment}-api"
  path                = "example"
  protocols           = ["https", "http"]
  description         = "An example API"

  subscription_key_parameter_names  {
    header = "Ocp-Apim-Subscription-Key"
    query = "access-key"
  }

  import {
    content_format = var.open_api_spec_content_format
    content_value  = var.open_api_spec_content_value
  }
}


resource "azurerm_api_management_api_operation_policy" "apiWelcomeTriggerPolicy" {
  api_name            = azurerm_api_management_api.api.name
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  resource_group_name = data.azurerm_resource_group.rg.name
  operation_id        = "WelcomeTrigger"

  xml_content = <<XML
 <policies>
    <inbound>
        <base />
        <set-backend-service base-url="https://${var.az_func_name}.azurewebsites.net" />
        <rewrite-uri template="/api/MngWelcomeTrigger" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>

XML
}

resource "azurerm_api_management_product" "product" {
  product_id            = "${var.environment}-product"
  resource_group_name   = data.azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.az_api_mng_svc.name
  display_name          = "${var.environment}-product"
  subscription_required = true
  approval_required     = false
  published             = true
  description           = "An example Product"
}

resource "azurerm_api_management_group" "group" {
  name                = "${var.environment}-group"
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  display_name        = "${var.environment}-group"
  description         = "An example group"
}

resource "azurerm_api_management_product_api" "product_api" {
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  product_id          = azurerm_api_management_product.product.product_id
  api_name            = azurerm_api_management_api.api.name
}

resource "azurerm_api_management_product_group" "product_group" {
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  product_id          = azurerm_api_management_product.product.product_id
  group_name          = azurerm_api_management_group.group.name
}

resource "azurerm_application_insights" "example" {
  name                = "example-appinsights"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "other"
}

resource "azurerm_api_management_logger" "example" {
  name                = "example-logger"
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  resource_group_name = data.azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.example.id

  application_insights {
    instrumentation_key = azurerm_application_insights.example.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "apiDiagnostics" {
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.az_api_mng_svc.name
  api_name = azurerm_api_management_api.api.name
  api_management_logger_id = azurerm_api_management_logger.example.id
  identifier = "applicationinsights"

  sampling_percentage       = 5.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }
}