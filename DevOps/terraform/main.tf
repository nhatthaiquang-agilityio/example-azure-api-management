terraform {
  required_providers {

    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.0, < 4.0"
    }
  }

  backend "azurerm" {

  }

}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}


# Azure Storage
resource "azurerm_storage_account" "example" {
  name                     = "${var.functionapp_storage_account_name}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "application_insights" {
  name                = "application-insights"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
}

# Azure Service Plan
resource "azurerm_service_plan" "example" {
  name                = "rk-app-service-plan01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Windows"
  # Windows Consumption
  sku_name            = "Y1"
}

# Azure Function
resource "azurerm_windows_function_app" "example" {
  name                = "${var.azurerm_windows_function_app_name}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location

  storage_account_name = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key
  service_plan_id      = azurerm_service_plan.example.id

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key,
  }

  site_config {
  }
}


resource "azurerm_api_management" "az_api_mng_svc" {
  name                = "${var.environment}-az-api-svc-mng"
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
        <set-backend-service base-url="https://${var.azurerm_windows_function_app_name}.azurewebsites.net" />
        <rewrite-uri template="/api/Welcome" />
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