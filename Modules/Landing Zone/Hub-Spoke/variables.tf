variable "location" {
  description = "(Required) location where this resource has to be created"
  default = "westeurope"
}
variable "prefix" {
    description = "customer prefix"
    default = "jvn"
}
variable "environment" {
    description = "prd,uat"
    default = "prd"
  
}