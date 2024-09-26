terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "env123" {
  type        = string
}
variable "subscription_id" {}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "example-rg" {
  name     = "mtc-resources"
  location = "West Europe"
  tags = {
    environment = "dev"
    dev123 = var.env123
  }
}

resource "azurerm_resource_group" "my-rg-123" {
  name     = "my-rg-test-123"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example-vn" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
    test        = "test123"
  }
}

resource "azurerm_subnet" "example-subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example-rg.name
  virtual_network_name = azurerm_virtual_network.example-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "example-nsg" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example-rg.location
  resource_group_name = azurerm_resource_group.example-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "example-dev-rule" {
  name                        = "example-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example-rg.name
  network_security_group_name = azurerm_network_security_group.example-nsg.name

}

resource "azurerm_subnet_network_security_group_association" "example-association" {
  subnet_id                 = azurerm_subnet.example-subnet.id
  network_security_group_id = azurerm_network_security_group.example-nsg.id
}

resource "azurerm_public_ip" "example-ip" {
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "example-nic" {
  name                = "example-nic"
  location            = azurerm_resource_group.example-rg.location
  resource_group_name = azurerm_resource_group.example-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "example-vm" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.example-rg.name
  location            = azurerm_resource_group.example-rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/examplekey.pub")
  }

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
    environment = "dev"
  }
}



