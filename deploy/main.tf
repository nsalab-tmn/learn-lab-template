terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.99"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
provider "azurerm" {
  features {}
}

variable "instance_id" {
  type = string
}
variable "tp_name" {
  type    = string
  default = ""
}
variable "tp_learn_env" {
  type    = string
  default = ""
}
variable "tp_learn_user" {
  type    = string
  default = ""
}
variable "variant_seed" {
  type    = string
  default = "0"
}
variable "location" {
  type    = string
  default = "uksouth"
}

resource "random_password" "ssh" {
  length  = 20
  special = false
}
resource "azurerm_resource_group" "learn" {
  name     = "rg-lab-${var.instance_id}"
  location = var.location
  tags = {
    learn_instance_id = var.instance_id
  }
}
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.instance_id}"
  address_space       = ["10.60.0.0/24"]
  location            = azurerm_resource_group.learn.location
  resource_group_name = azurerm_resource_group.learn.name
}
resource "azurerm_subnet" "sub" {
  name                 = "sub-${var.instance_id}"
  resource_group_name  = azurerm_resource_group.learn.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.0.0/25"]
}
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.instance_id}"
  location            = azurerm_resource_group.learn.location
  resource_group_name = azurerm_resource_group.learn.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.instance_id}"
  location            = azurerm_resource_group.learn.location
  resource_group_name = azurerm_resource_group.learn.name
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.instance_id}"
  location            = azurerm_resource_group.learn.location
  resource_group_name = azurerm_resource_group.learn.name
  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
resource "azurerm_network_interface_security_group_association" "a" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${var.instance_id}"
  resource_group_name             = azurerm_resource_group.learn.name
  location                        = azurerm_resource_group.learn.location
  size                            = "Standard_B1s"
  admin_username                  = "learner"
  admin_password                  = random_password.ssh.result
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  tags = {
    learn_instance_id = var.instance_id
    variant_seed      = var.variant_seed
  }
}
output "lab_host" {
  value = azurerm_public_ip.pip.ip_address
}
output "ssh_user" {
  value = "learner"
}
output "ssh_password" {
  value     = random_password.ssh.result
  sensitive = true
}
output "variant_seed" {
  value = var.variant_seed
}
