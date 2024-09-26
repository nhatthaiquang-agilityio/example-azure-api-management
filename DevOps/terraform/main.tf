data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_api_management" "apim_service" {
  name                = "${var.environment}-apim-service"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = "Example Publisher"
  publisher_email     = "nhat.thaiquang@asnet.com.vn"
  sku_name            = "Developer_1"
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
  api_management_name = azurerm_api_management.apim_service.name
  revision            = "1"
  display_name        = "${var.environment}-api"
  path                = "example"
  protocols           = ["https", "http"]
  description         = "An example API"

  import {
    content_format = var.open_api_spec_content_format
    content_value  = var.open_api_spec_content_value
  }
}

resource "azurerm_api_management_product" "product" {
  product_id            = "${var.environment}-product"
  resource_group_name   = data.azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.apim_service.name
  display_name          = "${var.environment}-product"
  subscription_required = true
  approval_required     = false
  published             = true
  description           = "An example Product"
}

resource "azurerm_api_management_group" "group" {
  name                = "${var.environment}-group"
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  display_name        = "${var.environment}-group"
  description         = "An example group"
}

resource "azurerm_api_management_product_api" "product_api" {
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  product_id          = azurerm_api_management_product.product.product_id
  api_name            = azurerm_api_management_api.api.name
}

resource "azurerm_api_management_product_group" "product_group" {
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
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
  api_management_name = azurerm_api_management.apim_service.name
  resource_group_name = data.azurerm_resource_group.rg.name
  resource_id         = azurerm_application_insights.example.id

  application_insights {
    instrumentation_key = azurerm_application_insights.example.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "apiDiagnostics" {
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim_service.name
  api_name = azurerm_api_management_api.api.name
  api_management_logger_id = azurerm_api_management_logger.example.id
  identifier = "applicationinsights"

  sampling_percentage       = 5.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "Verbose"
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