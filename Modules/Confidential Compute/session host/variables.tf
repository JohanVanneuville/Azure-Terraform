variable "location" {
  description = "(Required) location where this resource has to be created"
  default = "westeurope"
}

variable "prefix" {
    description = "customer prefix"
    default = "jvn"
}
variable "env" {
    description = "hub,prd,tst,dev,qa"
    default = "hub"
}
variable "spoke" {
    description = "hub,prd,tst,dev,qa"
    default = "prd"
}
variable "subscription_id_prd" {
    default = ""
  
}
variable "subscription_id_mgmt" {
    default = ""
  
}
variable "solution" {
    description = "can be sap,avd,..."
    default = "avd"
  
}
variable "subscription_id_avd" {
    default = ""
}
variable "subscription_id_identity" {
    default = ""
}
variable "workspace_key" {
    default = ""
}
variable "workspace_id" {
    default = ""
}
variable "vm_count" {
  description = "Number of Session Host VMs to create"
  default     = "1"
}
variable "subnet_id" {
  description = "Azure Subnet ID"
  default     = "/subscriptions/subid/resourceGroups/rg-prd-jvn-avd-networking-01/providers/Microsoft.Network/virtualNetworks/vnet-prd-jvn-avd-we-01/subnets/snet-prd-jvn-avd-shared-sessionhosts-01"

}
variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_DC2as_v5"
}

variable "image_publisher" {
  description = "Image Publisher"
  default     = "MicrosoftWindowsDesktop"
}

variable "image_offer" {
  description = "Image Offer"
  default     = "Windows-11"
}

variable "image_sku" {
  description = "Image SKU"
  default     = "win11-22h2-avd"
}

variable "image_version" {
  description = "Image Version"
  default     = "latest"
}

variable "admin_username" {
  description = "Local Admin Username"
  default     = "loc-admin"
}

variable "admin_password" {
  description = "Admin Password"
  default     = ""
}



variable "vm_name" {
  description = "Virtual Machine Name"
  default     = "vdh-prd-jvn-"
}


variable "vm_zones" {
  type        = list(any)
  description = "Number of zones"
  default     = ["1", "2", "3"]
}

variable "domain" {
  description = "johanvanneuville.com"
  default     = "johanvanneuville.com"
}

variable "domainuser" {
  description = "loc-admin"
  default     = "loc-admin"
}

variable "oupath" {
  description = "OU Path"
  default     = "OU=session hosts,OU=prd,OU=Azure Virtual Desktop,OU=Azure,DC=johanvanneuville,DC=com"
}

variable "domainpassword" {
  description = "Domain User Password"
  default     = ""
}


variable "hostpoolname" {
  description = "Host Pool Name to Register Session Hosts"
  default     = "hp-prd-jvn-avd-we-01"
}

variable "artifactslocation" {
  description = "Location of WVD Artifacts"
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_6-1-2021.zip"
}
variable "rfc3339" {
  default     = "2023-11-30T12:43:13Z"
  description = "token expiration"

}


