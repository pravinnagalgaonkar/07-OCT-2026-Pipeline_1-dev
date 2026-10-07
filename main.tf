terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "dev" {
  name     = "dev_rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet_dev" {
  name                = "dev_network"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_dev" {
  name                 = "dev_subnet"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.vnet_dev.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic_dev" {
  name                = "dev_nic"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_dev.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_dev" {
  name                = "dev_vm"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic_dev.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_public_key_path)
  }
}