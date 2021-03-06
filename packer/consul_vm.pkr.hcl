packer {
  required_version = ">= 0.12.0"
}

variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}

variable "client_secret" {
  type    = string
  default = "${env("ARM_CLIENT_SECRET")}"
}

variable "resource_group_name" {
  type = string
}

variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}

variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}

variable "location" {
  type    = string
  default = "UK South"
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}

source "azure-arm" "consul-ubuntu-1804" {
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  image_offer                       = "UbuntuServer"
  image_publisher                   = "Canonical"
  image_sku                         = "18.04-LTS"
  managed_image_name                = "consul-ubuntu-1804_${var.image_version}"
  managed_image_resource_group_name = "${var.resource_group_name}"
  location                          = "${var.location}"
  os_type                           = "Linux"
  subscription_id                   = "${var.subscription_id}"
  tenant_id                         = "${var.tenant_id}"
  vm_size                           = "Standard_DS2_v2"
  shared_image_gallery_destination {
    subscription = "${var.subscription_id}"
    resource_group = "${var.resource_group_name}"
    gallery_name = "sig_jared_holgate"
    image_name = "consul-ubuntu-1804"
    image_version = "${var.image_version}"
    replication_regions = [ "${var.location}" ]
  }
}

build {
  sources = ["source.azure-arm.consul-ubuntu-1804"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline          = [ 
      "DEBIAN_FRONTEND=noninteractive apt-get -y upgrade", 

      "sudo apt-get update", 
      "sudo apt-get install python curl ruby -y", 
      "sudo apt-get clean",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",

      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -", 
      "sudo apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt-get update",
      "sudo apt-get install consul -y"
    ]
    inline_shebang  = "/bin/sh -x"
  }
}
