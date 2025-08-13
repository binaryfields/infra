locals {
  # Port numbers
  all_ports      = -1
  apiserver_port = 6443
  kubelet_port   = 10250
  kubeproxy_port = 10256
  oke_port       = 12250
  node_port_min  = 30000
  node_port_max  = 32767
  ssh_port       = 22

  # Protocols
  # See https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
  all_protocols   = "all"
  icmp_protocol   = 1
  icmpv6_protocol = 58
  tcp_protocol    = 6
  udp_protocol    = 17

  anywhere          = "0.0.0.0/0"
  anywhere_ipv6     = "::/0"
  rule_type_nsg     = "NETWORK_SECURITY_GROUP"
  rule_type_cidr    = "CIDR_BLOCK"
  rule_type_service = "SERVICE_CIDR_BLOCK"

  # Oracle Services Network (OSN)
  osn = one(data.oci_core_services.all_services.services[*].cidr_block)

  # Tags
  common_tags = merge(var.freeform_tags, {
    Project     = var.cluster_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  # ADs
  availability_domains = data.oci_identity_availability_domains.ads.availability_domains
  ad_numbers_to_names  = { for i, ad in local.availability_domains : i + 1 => ad.name }
}
