terraform {
  required_version = ">= 0.15.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.42.0"
    }
  }
}