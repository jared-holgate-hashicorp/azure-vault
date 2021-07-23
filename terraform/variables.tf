variable "resource_group_name_prefix" {
  type = string
}

variable "deployment_environment" {
  type = string
}

variable "deployment_version" {
  type = string
}

variable "deployment_date" {
  type = string
}

variable "client_secret_for_unseal" {
  type      = string
  sensitive = true
}