variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "azurerm_windows_function_app_name" {
  type = string
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type = string
}

variable "functionapp_storage_account_name" {
  description = "The storage account name for azure function."
  type = string
}
