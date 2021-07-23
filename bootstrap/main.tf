terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
        }
        tfe = {
        }
        github = {
            source = "integrations/github"
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

provider "github" {
}

locals {
    environments = [ "test", "acpt", "prod" ]
    organization = "jared-holgate-hashicorp"
}

data "azurerm_client_config" "current" {
}

resource "tfe_workspace" "jfh" {
  for_each = { for env in local.environments : env => env }
  name         = "azure-vault-${each.value}"
  organization = local.organization
  description  = "Demonstration HashiCorp Vault on Azure ${each.value}"
}

resource "tfe_team" "jfh" {
  for_each = { for env in local.environments : env => env }
  name         = "azure-vault-${each.value}"
  organization = local.organization
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

resource "github_repository_environment" "repo_environment" {
  for_each = { for env in local.environments : env => env }  
  repository       = "jared-holgate-hashicorp/azure-vault"
  environment      = each.value

  dynamic "reviewers" {
      for_each = each.value == "test" ? {} : { reviewer = "jaredfholgate" } 
      content {
          users = [ reviewers.value.reviewer ]
      }
  }
}

resource "github_actions_environment_secret" "test_secret" {
  for_each = { for env in local.environments : env => env } 
  repository       = "jared-holgate-hashicorp/azure-vault"
  environment      = github_repository_environment.repo_environment[each.value].environment
  secret_name      = "TF_API_TOKEN"
  plaintext_value  = tfe_team_token.jfh[each.value].token
}