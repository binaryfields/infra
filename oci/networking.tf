locals {

  vcn_cidr = var.vcn_cidr

  default_cidrs = {
    cp     = { cidr = "10.0.1.0/30" }
    worker = { cidr = "10.0.2.0/24" }
    int_lb = { cidr = "10.0.3.0/24" }
    pub_lb = { cidr = "10.0.4.0/24" }
  }

  subnet_info = {
    cp     = { is_public = var.cluster_endpoint_is_public, dns_label = "cp" }
    worker = { is_public = false, dns_label = "wrk" }
    int_lb = { is_public = false, dns_label = "ilb" }
    pub_lb = { is_public = true, dns_label = "plb" }
  }

  subnets = { for k, v in local.subnet_info :
    k => merge(v, coalesce(lookup(var.subnets, k, null), lookup(local.default_cidrs, k, null), {}))
  }

  subnets_output = { for k, v in oci_core_subnet.oke : k => v }
  subnet_ids     = { for k, v in local.subnets_output : k => v.id }
}

# --- OKE VCN ---

resource "oci_core_vcn" "oke_vcn" {
  display_name   = "${var.cluster_name}-vcn"
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  dns_label      = replace(var.cluster_name, "-", "")
  freeform_tags  = local.common_tags

  lifecycle {
    ignore_changes = [freeform_tags, defined_tags, dns_label]
  }
}

# --- OKE Gateways ---

resource "oci_core_internet_gateway" "oke_inet" {
  display_name   = "${var.cluster_name}-internet-gateway"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags

  lifecycle {
    ignore_changes = [freeform_tags, defined_tags]
  }
}

resource "oci_core_nat_gateway" "oke_nat" {
  display_name   = "${var.cluster_name}-nat-gateway"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags

  lifecycle {
    ignore_changes = [freeform_tags, defined_tags]
  }
}

resource "oci_core_service_gateway" "oke_service" {
  display_name   = "${var.cluster_name}-service-gateway"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }

  lifecycle {
    ignore_changes = [freeform_tags, defined_tags]
  }
}

# --- OKE Route Tables ---

resource "oci_core_route_table" "oke_public" {
  display_name   = "${var.cluster_name}-public-rt"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.oke_inet.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Default route to Internet Gateway"
  }

  lifecycle {
    ignore_changes = [freeform_tags, defined_tags]
  }
}

resource "oci_core_route_table" "oke_private" {
  display_name   = "${var.cluster_name}-private-rt"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_nat_gateway.oke_nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Default route to NAT Gateway"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.oke_service.id
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    description       = "Route to OCI Services"
  }

  lifecycle {
    ignore_changes = [freeform_tags, defined_tags]
  }
}

# --- OKE Subnets ---

resource "oci_core_security_list" "oke" {
  for_each = local.subnets

  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-${each.key}"
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = var.freeform_tags

  lifecycle {
    ignore_changes = [
      freeform_tags, defined_tags, display_name,
      ingress_security_rules, egress_security_rules, # ignore for CCM-management
    ]
  }
}

resource "oci_core_subnet" "oke" {
  for_each = local.subnets

  display_name      = "${var.cluster_name}-${each.key}"
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.oke_vcn.id
  cidr_block        = each.value.cidr
  route_table_id    = tobool(each.value.is_public) ? oci_core_route_table.oke_public.id : oci_core_route_table.oke_private.id
  security_list_ids = compact([lookup(lookup(oci_core_security_list.oke, each.key, {}), "id", null)])

  dns_label                  = each.value.dns_label
  prohibit_public_ip_on_vnic = !tobool(each.value.is_public)
  freeform_tags              = local.common_tags

  lifecycle {
    ignore_changes = [
      freeform_tags, defined_tags, dns_label
    ]
  }
}

# --- Outputs ---

output "subnets" {
  description = "Created subnets with their IDs and CIDRs"
  value = { for k, v in local.subnets_output : k => {
    id   = v.id
    name = v.display_name
    cidr = v.cidr_block
  }}
}
