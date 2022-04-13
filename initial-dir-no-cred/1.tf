terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
  # to use azure service-principal
  subscription_id = ".."
  client_id       = ".."
  client_secret   = ".."
  tenant_id       = ".."
}

locals {
  env_variables_prod = {
    DOCKER_REGISTRY_SERVER_URL      = ".."
    DOCKER_REGISTRY_SERVER_USERNAME = ".."
    DOCKER_REGISTRY_SERVER_PASSWORD = ".."
  }
}

data "azurerm_resource_group" "rg" {
  name = "nginx-proxy"
}

resource "azurerm_virtual_network" "network_1" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_1" {
  name                 = "mySubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network_1.name
  address_prefixes     = ["10.0.1.0/24"]
}

data "azurerm_public_ip" "pip_1" {
  name                = "myPublicIP"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "nsg_1" {
  name                = "NSG-web-1"
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 937
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Http"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https_port"
    priority                   = 998
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic_1" {
  name                = "myNIC1"
  location            = "eastus"
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "web-ni-conf-1"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address            = "10.0.1.4"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = data.azurerm_public_ip.pip_1.id
  }
}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.nic_1.id
  network_security_group_id = azurerm_network_security_group.nsg_1.id
}

resource "azurerm_linux_virtual_machine" "vm_1" {
  name                  = "myVM1"
  location              = "eastus"
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_1.id]
  size                  = "Standard_b1s"
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data                     = base64encode(file("init.sh"))
  computer_name                   = "myvm1"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  connection {
    type        = "ssh"
    user        = "azureuser"
    private_key = file("~/.ssh/id_rsa")
    host        = "<pip-dns-label>"
  }
  provisioner "file" {
    source      = "./files-to-upload/"
    destination = "/home/azureuser/"
  }
  #  provisioner "remote-exec" {
  #    inline = ["chmod 400 ssh-keys/key*"]
  #  }
}
