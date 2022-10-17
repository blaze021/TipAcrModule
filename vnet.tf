resource "azurerm_virtual_network" "tip_vnet" {
  name                = "tipvnet"
  location            = azurerm_resource_group.acr-example.location
  resource_group_name = azurerm_resource_group.acr-example.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "tipacisnet" {
  name                 = "tip-aci-snet"
  resource_group_name  = azurerm_resource_group.acr-example.name
  virtual_network_name = azurerm_virtual_network.tip_vnet.name
  address_prefixes     = ["10.1.0.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_profile" "tipacinetprofile" {
  name                = "tipacinetprofile"
  location            = azurerm_resource_group.acr-example.location
  resource_group_name = azurerm_resource_group.acr-example.name

  container_network_interface {
    name = "tipnic"

    ip_configuration {
      name      = "tipipconfig"
      subnet_id = azurerm_subnet.tipacisnet.id
    }
  }
}