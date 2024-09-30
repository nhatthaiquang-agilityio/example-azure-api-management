variable "environment" {
  type = string
}

variable client_secret {
  type = string
}

variable subscription_id {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "az_func_name" {
  type = string
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type = string
}

variable "open_api_spec_content_format" {
  description = "The format of the content from which the API Definition should be imported. Possible values are: openapi, openapi+json, openapi+json-link, openapi-link, swagger-json, swagger-link-json, wadl-link-json, wadl-xml, wsdl and wsdl-link."
}

variable "open_api_spec_content_value" {
  description = "The Content from which the API Definition should be imported. When a content_format of *-link-* is specified this must be a URL, otherwise this must be defined inline."
}