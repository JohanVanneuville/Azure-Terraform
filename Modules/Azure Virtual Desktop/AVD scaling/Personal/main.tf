terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}
provider "azapi" {
}
provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.subscription_id_mgmt
}

data "azurerm_virtual_desktop_host_pool" "hp" {
  provider = azurerm.hub
  name = "vdpool-${var.spoke}-${var.prefix}-${var.solution}-04"
  resource_group_name = "rg-${var.spoke}-${var.prefix}-${var.solution}-backplane-01"
}
data "azurerm_resource_group" "hp-rg" {
  provider = azurerm.hub
    name = "rg-${var.spoke}-${var.prefix}-${var.solution}-backplane-01"
}

resource "azapi_resource" "weekdays_personal_schedule_root" {
  type      = "Microsoft.DesktopVirtualization/scalingPlans@2023-11-01-preview"
  name      = "scaling-p-prd-jvn-avd-01"
  location  = data.azurerm_virtual_desktop_host_pool.hp.location
  parent_id = data.azurerm_resource_group.hp-rg.id
   tags = {
    Environment = "avd"
    Costcenter = "IT"   
    Solution = "ScalingPlan" 
    HostPoolType = "Personal"
  }
  body = jsonencode({
    properties = {
      timeZone     = "W. Europe Standard Time",
      hostPoolType = "Personal",
      exclusionTag = "Maintenance",
      schedules    = [],
      hostPoolReferences = [
        {
          hostPoolArmPath    = data.azurerm_virtual_desktop_host_pool.hp.id,
          scalingPlanEnabled = true
        }
      ],
  } })
}


resource "azapi_resource" "weekdays_personal_schedule" {
  type  = "Microsoft.DesktopVirtualization/scalingPlans/personalSchedules@2023-11-01-preview"
  name  = "Weekdays"
  parent_id = azapi_resource.weekdays_personal_schedule_root.id
  body = jsonencode({
    properties = {
      daysOfWeek = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday"
      ]

      rampUpStartTime = {
        hour   = 7,
        minute = 0
      },
      rampUpAutoStartHosts            = "None",
      rampUpStartVMOnConnect          = "Enable",
      rampUpMinutesToWaitOnDisconnect = 45,
      rampUpActionOnDisconnect        = "Hibernate",
      rampUpMinutesToWaitOnLogoff     = 30,
      rampUpActionOnLogoff            = "Hibernate",

      peakStartTime = {
        hour   = 8,
        minute = 0
      },
      peakStartVMOnConnect          = "Enable",
      peakMinutesToWaitOnDisconnect = 60,
      peakActionOnDisconnect        = "Hibernate",
      peakMinutesToWaitOnLogoff     = 60,
      peakActionOnLogoff            = "Hibernate",

      rampDownStartTime = {
        hour   = 16,
        minute = 30
      },
      rampDownStartVMOnConnect          = "Enable",
      rampDownMinutesToWaitOnDisconnect = 45,
      rampDownActionOnDisconnect        = "Hibernate",
      rampDownMinutesToWaitOnLogoff     = 30,
      rampDownActionOnLogoff            = "Hibernate",

      offPeakStartTime = {
        hour   = 17,
        minute = 30
      },
      offPeakStartVMOnConnect          = "Enable",
      offPeakMinutesToWaitOnDisconnect = 20,
      offPeakActionOnDisconnect        = "Hibernate",
      offPeakMinutesToWaitOnLogoff     = 15,
      offPeakActionOnLogoff            = "Hibernate",
    }
  })
}
