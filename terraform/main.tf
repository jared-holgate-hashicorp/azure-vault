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
  source                       = "app.terraform.io/jared-holgate-hashicorp/stack_azure_hashicorp_vault/jaredholgate"
  resource_group_name          = format("%s%s", var.resource_group_name_prefix, var.deployment_environment)
  client_secret_for_unseal     = var.client_secret_for_unseal
  consul_cluster_image_version = "1.0.37"
  vault_cluster_image_version  = "1.0.37"
  consul_cluster_size          = 3 
  vault_cluster_size           = 3
  tags = {
    environment      = var.deployment_environment
    application-name = "Vault demonstration"
    owner            = "Jared Holgate"
  }
}