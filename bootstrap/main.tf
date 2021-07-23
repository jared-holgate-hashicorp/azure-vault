variable "client_secret_for_role" {
    type = string
}

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
        azuread = {
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

provider "azuread" {
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
  value        = azuread_service_principal_password.jfh.value
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Service Principal Client Secret"
  sensitive = true
}

resource "tfe_variable" "client_id" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_CLIENT_ID"
  value        = azuread_application.jfh.application_id
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
  key          = "TF_VAR_client_secret_for_unseal"
  value        = azuread_service_principal_password.jfh.value
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "The Azure Client Secret required for unsealing Vault"
  sensitive = true
}

resource "tfe_variable" "skip_provider_registration" {
  for_each = { for env in local.environments : env => env }  
  key          = "ARM_SKIP_PROVIDER_REGISTRATION"
  value        = "true"
  category     = "env"
  workspace_id = tfe_workspace.jfh[each.value].id
  description  = "Tell the Azure provider to skip provider registration on the subscription"
  sensitive = false
}

data "github_user" "current" {
  username = ""
}

resource "github_repository_environment" "repo_environment" {
  for_each = { for env in local.environments : env => env }  
  repository       = "azure-vault"
  environment      = each.value

  dynamic "reviewers" {
      for_each = each.value == "test" ? {} : { reviewer = "jaredfholgate" } 
      content {
          users = [ data.github_user.current.id ]
      }
  }
}

resource "github_actions_environment_secret" "test_secret" {
  for_each = { for env in local.environments : env => env } 
  repository       = "azure-vault"
  environment      = github_repository_environment.repo_environment[each.value].environment
  secret_name      = "TF_API_TOKEN"
  plaintext_value  = tfe_team_token.jfh[each.value].token
}

resource "azurerm_resource_group" "jfh" {
  for_each = { for env in local.environments : env => env }
  name     = "azure-vault-${each.value}"
  location = "UK South"
}

resource "azuread_application" "jfh" {
  for_each = { for env in local.environments : env => env }
  display_name               = "sp-azure-vault-${each.value}"
}

resource "azuread_service_principal" "jfh" {
  for_each = { for env in local.environments : env => env }
  application_id               = azuread_application.jfh[each.value].application_id
}

resource "azuread_service_principal_password" "jfh" {
  service_principal_id = azuread_service_principal.jfh[each.value].object_id
}

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "jfh" {
  for_each = { for env in local.environments : env => env }
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.jfh[each.value].object_id
}

module "resource_azure_ad_role_assignment" {
  source              = "app.terraform.io/jared-holgate-hashicorp/resource_azure_ad_role_assignment/jaredholgate"
  for_each = { for env in local.environments : env => env }
  client_id           = data.azurerm_client_config.current.client_id
  client_secret       = var.client_secret_for_role
  principal_id        = azuread_service_principal.jfh[each.value].object_id
  role_definition_id  = "e8611ab8-c189-46e8-94e1-60213ab1f814"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}