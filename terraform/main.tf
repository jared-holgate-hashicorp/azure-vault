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

provider "azurerm" {
    features {}
}

module "stack_azure_hashicorp_vault" {
    source  = "app.terraform.io/jared-holgate-hashicorp/stack_azure_hashicorp_vault/jaredholgate"
    resource_group_name = format("%s%s", var.resource_group_name_prefix, var.deployment_environment)
    client_secret_for_unseal = var.client_secret_for_unseal
    tags = {
        environment = var.deployment_environment
        version = var.deployment_version
        date-deployed = var.deployment_date
        application-name = "Vault demonstration"
        owner = "Jared Holgate"
    }
}