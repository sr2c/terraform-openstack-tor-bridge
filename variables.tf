variable "contact_info" {
  type = string
  description = "Contact information to be published in the bridge descriptor."
}

variable "external_network_name" {
  type = string
  description = "Name of the Openstack network that provides Internet access."
  default = "Ext-Net"
}

variable "flavor_name" {
  type = string
  description = "Name of the flavor to use for the compute instance."
  default = "d2-2"
}

variable "image_name" {
  type = string
  description = "Name of the image to use for the compute instance (must be Debian 10 based)."
  default = "Debian 10"
}

variable "region" {
  type = string
  description = "Region to deploy the instance in."
  default = null
}

variable "ssh_key" {
  type = string
  description = "Public SSH key for provisioning."
}

variable "ssh_username" {
  type = string
  description = "Username to use for SSH access (must have password-less sudo enabled)."
  default = "debian"
}