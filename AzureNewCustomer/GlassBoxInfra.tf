###Variables
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}
variable "customer_name" {}
variable "customer_location" {}
variable "vmpassword" {}


###Provider
provider "azurerm" {
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
}

resource "azurerm_resource_group" "customerrg" {
  name     = "${var.customer_name}-RG"
  location = "${var.customer_location}"

  tags {
    Customer  = "${var.customer_name}"
    CreatedBy = "Terraform"
  }
}

resource "azurerm_network_security_group" "customernsg" {
  name                = "${var.customer_name}-nsg"
  location            = "${azurerm_resource_group.customerrg.location}"
  resource_group_name = "${azurerm_resource_group.customerrg.name}"

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

  tags {
    Customer = "${var.customer_name}"
  }
}

resource "azurerm_virtual_network" "customervnet" {
  name                = "${var.customer_name}-VNET"
  location            = "${azurerm_resource_group.customerrg.location}"
  resource_group_name = "${azurerm_resource_group.customerrg.name}"
  address_space       = ["172.32.0.0/16"]

  tags = {
    Customer = "${var.customer_name}"
  }
}

resource "azurerm_subnet" "gbpub" {
  name                 = "GB-${var.customer_name}-Pub"
  resource_group_name  = "${azurerm_resource_group.customerrg.name}"
  virtual_network_name = "${azurerm_virtual_network.customervnet.name}"
  address_prefix       = "172.32.1.0/24"
}

resource "azurerm_subnet" "gbconsole" {
  name                 = "GB-${var.customer_name}-Console"
  resource_group_name  = "${azurerm_resource_group.customerrg.name}"
  virtual_network_name = "${azurerm_virtual_network.customervnet.name}"
  address_prefix       = "172.32.3.0/24"
}

resource "azurerm_subnet" "gbdata" {
  name                 = "GB-${var.customer_name}-Data"
  resource_group_name  = "${azurerm_resource_group.customerrg.name}"
  virtual_network_name = "${azurerm_virtual_network.customervnet.name}"
  address_prefix       = "172.32.2.0/24"
}

resource "azurerm_subnet" "gbpubhosts" {
  name                 = "GB-${var.customer_name}-Pub-Hosts"
  resource_group_name  = "${azurerm_resource_group.customerrg.name}"
  virtual_network_name = "${azurerm_virtual_network.customervnet.name}"
  address_prefix       = "172.32.4.0/24"
}
resource "azurerm_subnet_network_security_group_association" "gbpubhostsnsg" {
  subnet_id                 = "${azurerm_subnet.gbpubhosts.id}"
  network_security_group_id = "${azurerm_network_security_group.customernsg.id}"
}

resource "azurerm_subnet" "gbconsolehosts" {
  name                 = "GB-${var.customer_name}-Console-Hosts"
  resource_group_name  = "${azurerm_resource_group.customerrg.name}"
  virtual_network_name = "${azurerm_virtual_network.customervnet.name}"
  address_prefix       = "172.32.5.0/24"
}

resource "azurerm_network_interface" "g01nic" {
  name                      = "g01-nic"
  location                  = "${azurerm_resource_group.customerrg.location}"
  resource_group_name       = "${azurerm_resource_group.customerrg.name}"
  network_security_group_id = "${azurerm_network_security_group.customernsg.id}"

  ip_configuration {
    name                          = "g01myNicConfiguration"
    subnet_id                     = "${azurerm_subnet.gbpubhosts.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.managevmpip.id}"
  }

  tags {
    Customer = "${var.customer_name}"
  }
}

resource "azurerm_network_interface" "g02nic" {
  name                      = "g02-nic"
  location                  = "${azurerm_resource_group.customerrg.location}"
  resource_group_name       = "${azurerm_resource_group.customerrg.name}"
  network_security_group_id = "${azurerm_network_security_group.customernsg.id}"

  ip_configuration {
    name                          = "g02myNicConfiguration"
    subnet_id                     = "${azurerm_subnet.gbpubhosts.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    Customer = "${var.customer_name}"
  }
}

resource "azurerm_network_interface" "a01nic" {
  name                = "a01-nic"
  location            = "${azurerm_resource_group.customerrg.location}"
  resource_group_name = "${azurerm_resource_group.customerrg.name}"

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = "${azurerm_subnet.gbdata.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    Customer = "${var.customer_name}"
  }
}

resource "azurerm_network_interface" "s01nic" {
  name                = "s01-nic"
  location            = "${azurerm_resource_group.customerrg.location}"
  resource_group_name = "${azurerm_resource_group.customerrg.name}"

  ip_configuration {
    name                          = "s01myNicConfiguration"
    subnet_id                     = "${azurerm_subnet.gbconsolehosts.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    Customer = "${var.customer_name}"
  }
}
resource "azurerm_public_ip" "managevmpip" {
    name                         = "${var.customer_name}-managevmpip"
    location                     = "${azurerm_resource_group.customerrg.location}"
    resource_group_name          = "${azurerm_resource_group.customerrg.name}"
    allocation_method            = "Dynamic"

    tags {
        Customer = "${var.customer_name}"
    }
}
resource "azurerm_public_ip" "lbpip" {
    name                         = "${azurerm_resource_group.customerrg.name}-lbip"
    location                     = "${azurerm_resource_group.customerrg.location}"
    resource_group_name          = "${azurerm_resource_group.customerrg.name}"
    allocation_method            = "Dynamic"
}
resource "azurerm_public_ip" "lbpip2" {
    name                         = "${azurerm_resource_group.customerrg.name}-lbip2"
    location                     = "${azurerm_resource_group.customerrg.location}"
    resource_group_name          = "${azurerm_resource_group.customerrg.name}"
    allocation_method            = "Dynamic"
}


resource "azurerm_availability_set" "gbas" {
  name                         = "${var.customer_name}"
  location                     = "${azurerm_resource_group.customerrg.location}"
  resource_group_name          = "${azurerm_resource_group.customerrg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "g01vm" {
  name                  = "g01"
  location              = "${azurerm_resource_group.customerrg.location}"
  resource_group_name   = "${azurerm_resource_group.customerrg.name}"
  network_interface_ids = ["${azurerm_network_interface.g01nic.id}"]
  vm_size               = "Standard_D4s_v3"
  availability_set_id   = "${azurerm_availability_set.gbas.id}"

  storage_os_disk {
    name              = "gb01osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "g01datadisk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "100"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "g01"
    admin_username = "azureuser"
    admin_password = "${var.vmpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    Customer = "${var.customer_name}"
  }
}
resource "azurerm_virtual_machine" "g02vm" {
  name                  = "g02"
  location              = "${azurerm_resource_group.customerrg.location}"
  resource_group_name   = "${azurerm_resource_group.customerrg.name}"
  network_interface_ids = ["${azurerm_network_interface.g02nic.id}"]
  vm_size               = "Standard_D4s_v3"
  availability_set_id   = "${azurerm_availability_set.gbas.id}"

  storage_os_disk {
    name              = "gb02osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "g02datadisk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "100"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "g02"
    admin_username = "azureuser"
    admin_password = "${var.vmpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    Customer = "${var.customer_name}"
  }
}
resource "azurerm_virtual_machine" "a01vm" {
  name                  = "a01"
  location              = "${azurerm_resource_group.customerrg.location}"
  resource_group_name   = "${azurerm_resource_group.customerrg.name}"
  network_interface_ids = ["${azurerm_network_interface.a01nic.id}"]
  vm_size               = "Standard_D8s_v3"

  storage_os_disk {
    name              = "a01osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "a01datadisk1"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "100"
  }
  storage_data_disk {
    name              = "a01datadisk2"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 1
    disk_size_gb      = "100"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "a01"
    admin_username = "azureuser"
    admin_password = "${var.vmpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    Customer = "${var.customer_name}"
  }
}
resource "azurerm_virtual_machine" "s01vm" {
  name                  = "s01"
  location              = "${azurerm_resource_group.customerrg.location}"
  resource_group_name   = "${azurerm_resource_group.customerrg.name}"
  network_interface_ids = ["${azurerm_network_interface.s01nic.id}"]
  vm_size               = "Standard_D4s_v3"

  storage_os_disk {
    name              = "s01osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "s01datadisk1"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "100"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_profile {
    computer_name  = "s01"
    admin_username = "azureuser"
    admin_password = "${var.vmpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    Customer = "${var.customer_name}"
  }
}
resource "azurerm_application_gateway" "gatewaynetwork" {
    name                = "GB-${var.customer_name}-Console-LB"
    location            = "${azurerm_resource_group.customerrg.location}"
    resource_group_name = "${azurerm_resource_group.customerrg.name}"
    sku {
        name           = "Standard_Small"
        tier           = "Standard"
        capacity       = 2
    }
    gateway_ip_configuration {
        name         = "${azurerm_virtual_network.customervnet.name}-gwip-cfg"
        subnet_id    = "${azurerm_virtual_network.customervnet.id}/subnets/${azurerm_subnet.gbconsole.name}"
    }
    frontend_port {
        name         = "${azurerm_virtual_network.customervnet.name}-feport"
        port         = 80
    }
    frontend_ip_configuration {
        name         = "${azurerm_virtual_network.customervnet.name}-feip"  
        public_ip_address_id = "${azurerm_public_ip.lbpip.id}"
    }
    backend_address_pool {
        name = "${azurerm_virtual_network.customervnet.name}-beap"
    }
    backend_http_settings {
        name                  = "${azurerm_virtual_network.customervnet.name}-be-htst"
        cookie_based_affinity = "Disabled"
        port                  = 8443
        protocol              = "Http"
        request_timeout        = 20
    }
    http_listener {
        name                                  = "${azurerm_virtual_network.customervnet.name}-httplstn"
        frontend_ip_configuration_name        = "${azurerm_virtual_network.customervnet.name}-feip"
        frontend_port_name                    = "${azurerm_virtual_network.customervnet.name}-feport"
        protocol                              = "Http"
    }
    request_routing_rule {
        name                       = "${azurerm_virtual_network.customervnet.name}-rqrt"
        rule_type                  = "Basic"
        http_listener_name         = "${azurerm_virtual_network.customervnet.name}-httplstn"
        backend_address_pool_name  = "${azurerm_virtual_network.customervnet.name}-beap"
        backend_http_settings_name = "${azurerm_virtual_network.customervnet.name}-be-htst"
    }
}
resource "azurerm_application_gateway" "reportgatewaynetwork" {
    name                = "GB-${var.customer_name}-Report-LB"
    location            = "${azurerm_resource_group.customerrg.location}"
    resource_group_name = "${azurerm_resource_group.customerrg.name}"
    sku {
        name           = "Standard_Small"
        tier           = "Standard"
        capacity       = 2
    }
    gateway_ip_configuration {
        name         = "${azurerm_virtual_network.customervnet.name}-gwip-report"
        subnet_id    = "${azurerm_virtual_network.customervnet.id}/subnets/${azurerm_subnet.gbpub.name}"
    }
    frontend_port {
        name         = "${azurerm_virtual_network.customervnet.name}-feport"
        port         = 80
    }
    frontend_ip_configuration {
        name         = "${azurerm_virtual_network.customervnet.name}-feip"  
        public_ip_address_id = "${azurerm_public_ip.lbpip2.id}"
    }
    backend_address_pool {
        name = "${azurerm_virtual_network.customervnet.name}-beap"
    }
    backend_http_settings {
        name                  = "${azurerm_virtual_network.customervnet.name}-be-htst"
        cookie_based_affinity = "Disabled"
        port                  = 80
        protocol              = "Http"
        request_timeout        = 1
    }
    http_listener {
        name                                  = "${azurerm_virtual_network.customervnet.name}-httplstn"
        frontend_ip_configuration_name        = "${azurerm_virtual_network.customervnet.name}-feip"
        frontend_port_name                    = "${azurerm_virtual_network.customervnet.name}-feport"
        protocol                              = "Http"
    }
    request_routing_rule {
        name                       = "${azurerm_virtual_network.customervnet.name}-rqrt"
        rule_type                  = "Basic"
        http_listener_name         = "${azurerm_virtual_network.customervnet.name}-httplstn"
        backend_address_pool_name  = "${azurerm_virtual_network.customervnet.name}-beap"
        backend_http_settings_name = "${azurerm_virtual_network.customervnet.name}-be-htst"
    }
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgatwaybackendassociation" {
  network_interface_id    = "${azurerm_network_interface.s01nic.id}"
  ip_configuration_name   = "s01myNicConfiguration"
  backend_address_pool_id = "${azurerm_application_gateway.gatewaynetwork.backend_address_pool.0.id}"
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgatwaybackendassociation2" {
  network_interface_id    = "${azurerm_network_interface.g01nic.id}"
  ip_configuration_name   = "g01myNicConfiguration"
  backend_address_pool_id = "${azurerm_application_gateway.reportgatewaynetwork.backend_address_pool.0.id}"
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgatwaybackendassociation3" {
  network_interface_id    = "${azurerm_network_interface.g02nic.id}"
  ip_configuration_name   = "g02myNicConfiguration"
  backend_address_pool_id = "${azurerm_application_gateway.reportgatewaynetwork.backend_address_pool.0.id}"
}