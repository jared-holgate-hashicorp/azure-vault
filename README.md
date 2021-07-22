# Example Vault deployment on Azure, using Packer and Terraform

## Demo steps

1. RDP onto Demo
2. Save the SSH key into c:\users\adminuser\adminuser.pem
3. Open an SSH session to one of the Vault VM's
```
ssh -i adminuser.pem adminuser@10.1.1.10
```
4. Run these commands to show the Consul Cluster and the Vault status;
```
export VAULT_ADDR=http://127.0.0.1:8200
consul members
consul operator raft list-peers
vault status
```
5. Demonstrate getting a dynamic SP cred from Azure.
```
cat /opt/vault/init.log
vault login token=
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

## References

https://learn.hashicorp.com/tutorials/vault/ha-with-consul
https://learn.hashicorp.com/tutorials/vault/autounseal-azure-keyvault?in=vault/auto-unseal
https://github.com/hashicorp/vault-guides/blob/master/operations/azure-keyvault-unseal/setup.tpl
https://www.vaultproject.io/docs/secrets/azure
