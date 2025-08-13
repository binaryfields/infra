terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.6"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_id
  user_ocid        = var.user_id
  private_key_path = var.api_private_key_path
  fingerprint      = var.api_fingerprint
  region           = var.region
}
