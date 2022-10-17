resource "azurerm_resource_group" "acr-example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "tipcontainerRegistry1"
  resource_group_name = azurerm_resource_group.acr-example.name
  location            = azurerm_resource_group.acr-example.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "East US"
    zone_redundancy_enabled = true
    tags = {
      Environment = "Dev"
    }
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags = {
      Environment = "Dev"
    }
  }
}
data "azurerm_subscription" "tipsub" {
  subscription_id = "b7625216-1399-4f84-8eae-3339444fdfa0"
}

data "azurerm_client_config" "tipclient" {
}

resource "azurerm_role_assignment" "example" {
  scope                = data.azurerm_subscription.tipsub.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.tipclient.object_id
}

variable "image_name" {
  default = "tip-demo"
}
resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<-EOT
        docker login ${azurerm_container_registry.acr.login_server}
        docker tag ${var.image_name} ${azurerm_container_registry.acr.login_server}
        docker push ${azurerm_container_registry.acr.login_server}
      EOT
    # command = <<-EOT
    #         mkdir t
    #         mkdir r
    #     EOT
    # inline = [
    #   "mkdir ./t"
    # ]

  }
}

resource "azurerm_container_group" "tipcontainergroup" {
  name                = "tip-container-group"
  location            = azurerm_resource_group.acr-example.location
  resource_group_name = azurerm_resource_group.acr-example.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.tipacinetprofile.id
  os_type             = "Linux"

  container {
    name   = "azure_instance"
    image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  tags = {
    environment = "testing"
  }
}