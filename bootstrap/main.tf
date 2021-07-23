terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
        }
        tfe = {
        }
    }

    backend "remote" {
        organization = "jared-holgate-hashicorp"

        workspaces {
            name = "bootstrap"
        }
    }
}

provider "azurerm" {
    features {}
}

provider "tfe" {
}

locals {
    environments = [ "temp", "acpt", "prod" ]
}

data "azurerm_client_config" "current" {
}

resource "tfe_organization" "jfh" {
  name  = "jared-holgate-hashicorp"
  email = "jaredfholgate@gmail.com"
}

resource "tfe_workspace" "jfh" {
  for_each = { for env in local.environments : env => env }
  name         = "azure-vault-${each.value}"
  organization = tfe_organization.jfh.id
  description  = "Demonstration HashiCorp Vault on Azure ${each.value}"
}

resource "tfe_team" "jfh" {
  for_each = { for env in local.environments : env => env }
  name         = "azure-vault-${each.value}"
  organization = tfe_organization.jfh.id
}

resource "tfe_team_access" "jfh" {
  for_each = { for env in local.environments : env => env }
  access       = "write"
  team_id      = tfe_team.jfh[each.value].id
  workspace_id = tfe_workspace.jfh[each.value].id
}

resource "tfe_team_token" "jfh" {
  for_each = { for env in local.environments : env => env }
  team_id = tfe_team.jfh[each.value].id
}

resource "tfe_variable" "client_secret" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_CLIENT_SECRET"
  value        = "TBC"
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Service Principal Client Secret"
  sensitive = true
}

resource "tfe_variable" "client_id" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_CLIENT_ID"
  value        = "TBC"
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Service Principal Client Id"
  sensitive = true
}

resource "tfe_variable" "tenant_id" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_TENTANT_ID"
  value        = data.azurerm_client_config.current.tenant_id
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Tenant Id"
  sensitive = true
}

resource "tfe_variable" "subscription_id" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_SUBSCRIPTION_ID"
  value        = data.azurerm_client_config.current.subscription_id
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Subcription Id"
  sensitive = true
}

resource "tfe_variable" "client_secret_for_unseal" {
  for_each = { for env in local.environments : env => env }  
  key          = "TF_VAR_client_secret_for_unseal "
  value        = "TBC"
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Client Secret required for unsealing Vault"
  sensitive = true
}

resource "tfe_variable" "skip_provider_registration" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_SKIP_PROVIDER_REGISTRATION "
  value        = "true"
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "Tell the Azure provider to skip provider registration on the subscription"
  sensitive = false
}

output "tf_team_tokens" {
  value = toset([
    for tt in tfe_team_token.jfh : nonsensitive(tt.token)
  ])
}