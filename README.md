# Example HashiCorp Vault cluster deployment, backed by HashiCorp Consul onto Microsoft Azure, using HashiCorp Packer and HashiCorp Terraform

This example uses a terraform module to deploy a HashiCorp Vault cluster on IaaS into Microsoft Azure. The Vault cluster is backed by a HashiCorp Consul cluster. The virtual machines are deployed from templates that have been defined and built by HashiCorp Packer.

The demo itself uses GitHub Actions and Terraform Cloud to deploy the terraform.

## What does the example consist of?

### https://github.com/jared-holgate-hashicorp/azure-vault

This is the main repository, it contains these folders;

#### bootstrap

This folder contains the terraform that sets up environment accross GitHub, Terraform Cloud and Microsoft Azure ready to deploy to. It performs the following steps;

1. Creates test, acpt and prod workspaces in Terraform Cloud.
2. Creates test, acpt and prod Resource Groups in Azure.
3. Creates test, acpt and prod Service Principals in Azure and assingns the relevant permissions to each resource group.
4. Creates the variables in Terraform Cloud using the credetnaisl of the Azure Service Principals.
5. Creates test, actp and prod Teams in Terraform Cloud and assigns write permissions on the respective workspace.
6. Creates test, acpt and prod environments for this reposiory in GitHub and adds the relevant Terraform Cloud Team API token and approvals.

This pipeline just need to be run once for the initial setup.

#### packer

This folder contains the Packer HCL configuration for the Consul and Vault VM's. They perform the following steps;

1. Install Consul onto the Consul VM.
2. Install Consul and Vault onto the Vault VM.

These installs significantly decrease the time taken to deploy and configure the VM's at later stages.

#### terraform

This folder contains the terraform that actually deploys the Consul and Vault clusters along with Networking and Key Vault. It uses a terraform module defined in the https://github.com/jared-holgate-hashicorp/terraform-jaredholgate-stack_azure_hashicorp_vault repository to achieve this.

#### .github/workflows

This folder contains the GitHub Actions definitions. There is one for each of the folders mentioned above;

1. packer.yaml uses the https://github.com/marketplace/actions/packer-github-actions steps to vailidate and build the Packer templates, pushing them to the Azure Shared Image Gallery.
2. 



## Demo steps

1. RDP onto Demo VM

2. Save the SSH key into c:\users\adminuser\adminuser.pem

3. Open an SSH session to one of the Vault VM's
```
ssh -i adminuser.pem adminuser@10.1.1.10
```

4. Show the cloud_init logs
```
cat /var/log/cloud-init-output.log
```

5. Run these commands to show the Consul Cluster and the Vault status;
```
export VAULT_ADDR=http://127.0.0.1:8200
consul members
consul operator raft list-peers
vault status
```

6. Demonstrate getting a dynamic SP cred from Azure.
```
export VAULT_ADDR=http://127.0.0.1:8200
vault login [Replace Me]

vault write azure/roles/my-role ttl=1h azure_roles=-<<EOF
    [
        {
            "role_name": "Contributor",
            "scope":  "/subscriptions/f843cc47-4ba2-4489-8839-23581b71de34"
        }
    ]
EOF

vault read azure/creds/my-role
```

7. Show the Vault UI working.
```
https://10.1.1.11:8200/ui
```
