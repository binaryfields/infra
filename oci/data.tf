data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}
