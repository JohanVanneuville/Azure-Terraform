variable "prefix" {
    description = "customer prefix"
    default = "jvn"
}
variable "location" {
  description = "(Required) location where this resource has to be created"
  default = "westeurope"
}
variable "res_group" {
  description = "The name of the resource group in which to create the Azure resources"
  default = "rg-jvn-avd-session-hosts"
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
  default = "avd-join"
}

variable "admin_password" {
  description = "Admin Password"
  default = ""
}

variable "subnet_id" {
  description = "Azure Subnet ID"
  default = ""

}

variable "vm_name" {
  description = "Virtual Machine Name"
  default = "vm-jvn-avd-"
}

variable "vm_count" {
  description = "Number of Session Host VMs to create" 
  default = "2"
}

variable "domain" {
  description = "Domain to join" 
  default = ""
}

variable "domainuser" {
  description = "Domain Join User Name" 
  default = ""
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
  default = "hp-prod-jvn-avd-weu-01"
  }

variable "artifactslocation" {
  description = "Location of WVD Artifacts" 
  default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"
}
variable "rfc3339" {
  default = "2022-05-30T12:43:13Z"
  description = "token expiration"
  
}
