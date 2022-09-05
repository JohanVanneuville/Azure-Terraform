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
