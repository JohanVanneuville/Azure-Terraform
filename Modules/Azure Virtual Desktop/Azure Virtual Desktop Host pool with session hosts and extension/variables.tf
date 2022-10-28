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

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default = "Standard_B2ms"
}

variable "image_publisher" {
  description = "Image Publisher"
  default = "MicrosoftWindowsDesktop"
}

variable "image_offer" {
  description = "Image Offer"
  default = "Windows-11"
}

variable "image_sku" {
  description = "Image SKU"
  default = "win11-21h2-avd"
}

variable "image_version" {
  description = "Image Version"
  default = "latest"
}

variable "admin_username" {
  description = "Local Admin Username"
  default = "loc-admin"
}

variable "admin_password" {
  description = "Admin Password"
  default = ""
}

variable "subnet_id" {
  description = "Azure Subnet ID"
  default = "/subscriptions/578b51a7-e51d-4844-a70f-d7a1cf662250/resourceGroups/rg-prd-jvn-avd-networking-01/providers/Microsoft.Network/virtualNetworks/vnet-prd-jvn-avd-we-01/subnets/snet-prd-jvn-avd-session-hosts-01"

}

variable "vm_name" {
  description = "Virtual Machine Name"
  default = "avd-prd-jvn-"
}

variable "vm_count" {
  description = "Number of Session Host VMs to create" 
  default = "4"
}
variable "vm_zones" {
  type = list
  description = "Number of zones" 
  default = ["1","2","3"]
}

variable "domain" {
  description = "" 
  default = ""
}

variable "domainuser" {
  description = "loc-admin" 
  default = "loc-admin"
}

variable "oupath" {
  description = "OU Path"
  default = ""
}

variable "domainpassword" {
  description = "Domain User Password" 
  default = ""
}


variable "hostpoolname" {
  description = "Host Pool Name to Register Session Hosts" 
  default = "hp-prd-jvn-avd-we-01"
  }

variable "artifactslocation" {
  description = "Location of WVD Artifacts" 
  default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_6-1-2021.zip"
}
variable "rfc3339" {
  default = "2022-10-30T12:43:13Z"
  description = "token expiration"
  
}
variable "workspace_key" {
    default = ""
}
variable "workspace_id" {
    default = ""
}

