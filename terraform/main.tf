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


terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
        }
    }

    backend "remote" {
        organization = "jared-holgate-hashicorp"

        workspaces {
            prefix = "azure-vault-"
        }
    }
}

module "stack_azure_hashicorp_vault" {
    source  = "app.terraform.io/jared-holgate-hashicorp/stack_azure_hashicorp_vault/jaredholgate"
    environment = var.deployment_environment
    resource_group_name = format("%s-%s", var.resource_group_name_prefix)
}

output "ssh_key" {
    value = module.stack_azure_vault.ssh_key
    sensitive = true
}