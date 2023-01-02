terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.37.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.subscription_id_mgmt
}
provider "azurerm" {
  features {}
  alias           = "prod"
  subscription_id = var.subscription_id_prd
}
provider "azurerm" {
  features {}
  alias           = "identity"
  subscription_id = var.subscription_id_identity
}
provider "azurerm" {
  features {}
  alias           = "avd"
  subscription_id = var.subscription_id_avd
}


data "azurerm_log_analytics_workspace" "law" {
  provider            = azurerm.hub
  name                = "law-${var.env}-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01"
}
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "mgmt" {
  provider = azurerm.hub
  name     = "rg-hub-jvn-management-01"
}
resource "azurerm_security_center_automation" "continous_export" {
  name                = "ExportToWorkspace"
  location            = data.azurerm_resource_group.mgmt.location
  resource_group_name = data.azurerm_resource_group.mgmt.name
  action {
    type        = "loganalytics"
    resource_id = "/subscriptions/[subid]/resourcegroups/rg-hub-jvn-management-01/providers/microsoft.operationalinsights/workspaces/law-hub-jvn-01"
  }
  source {
    event_source = "Alerts"
    rule_set {
      rule {
        property_path  = "severity"
        operator       = "Equals"
        expected_value = "High"
        property_type  = "String"
      }
       rule {
        property_path  = "severity"
        operator       = "Equals"
        expected_value = "Low"
        property_type  = "String"
      }
       rule {
        property_path  = "severity"
        operator       = "Equals"
        expected_value = "Medium"
        property_type  = "String"
      }
       rule {
        property_path  = "severity"
        operator       = "Equals"
        expected_value = "Informational"
        property_type  = "String"
      }

    }
  }
  source {
    event_source = "SecureScores"
  }
  source {
    event_source = "SecureScoreControls"
  }
  source {
   event_source = "RegulatoryComplianceAssessment"
  }
  source {
    event_source = "Recommendations"
    rule_set {
      rule {
        property_path  = "severity"
        operator       = "Equals"
        expected_value = "High"
        property_type  = "String"
      }
    }
  }
  scopes = [ data.azurerm_subscription.current.id ]
}
