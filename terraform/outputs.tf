output "ssh_key" {
    value = module.stack_azure_hashicorp_vault.ssh_key
}

output "demo_password" {
  value = module.stack_azure_hashicorp_vault.demo_password
}

output "demo_public_ip_address" {
  value = module.stack_azure_hashicorp_vault.demo_public_ip_address
}