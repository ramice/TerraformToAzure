# TF file that deploys 	Standard_B1s (free tier) VM with Ubunty 19.4 together with SSH Key authentication line 56. Don’t forget to generate and place SSL
# certificate to your local machine  (on Windows is should be here C:\Users\YourUsername\.ssh )
# Port 22 is open for SSH via public IP (dynamic public ip)
# Zone is Europe West
# main.tf file can be run from terraform directory (for sake of simplicity) assuming that terraform installation, AzureCli and you are authenticated to your Azure
# Emir Ramic, eramic@hotmail.com

#Configure Provider (AWS, Azure....)
provider "azurerm" {
  features {}
}

#Creation of resources
resource "azurerm_resource_group" "ubuntu" {
  name     = "emirdemo-resources"
  location = "westeurope"
}

resource "azurerm_virtual_network" "ubuntu" {
  name                = "emirdemo-network"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.ubuntu.location
  resource_group_name = azurerm_resource_group.ubuntu.name
}

resource "azurerm_subnet" "ubuntu" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.ubuntu.name
  virtual_network_name = azurerm_virtual_network.ubuntu.name
  address_prefixes     = ["192.168.5.0/24"]
}

resource "azurerm_network_interface" "ubuntu" {
  name                = "emirdemo-nic"
  location            = azurerm_resource_group.ubuntu.location
  resource_group_name = azurerm_resource_group.ubuntu.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ubuntu.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu.id
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                = "emirdemoubuntu-machine"
  resource_group_name = azurerm_resource_group.ubuntu.name
  location            = azurerm_resource_group.ubuntu.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.ubuntu.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "19.04"
    version   = "latest"
  }

}

resource "azurerm_public_ip" "ubuntu" {
  name                = "emirUbuntupublicip79"
  resource_group_name = azurerm_resource_group.ubuntu.name
  location            = azurerm_resource_group.ubuntu.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "TestDev"
  }
}

resource "azurerm_network_security_group" "ubuntu" {
  name                = "emirSG-security-group1"
  location            = azurerm_resource_group.ubuntu.location
  resource_group_name = azurerm_resource_group.ubuntu.name

  security_rule {
    name                       = "SSHin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "TestDev"
  }
}
resource "azurerm_network_interface_security_group_association" "ubuntu" {
    network_interface_id      = azurerm_network_interface.ubuntu.id
    network_security_group_id = azurerm_network_security_group.ubuntu.id
}
