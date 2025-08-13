locals {
  # NSGs
  control_plane_nsg_id = one(oci_core_network_security_group.oke_control_plane[*].id)
  worker_nsg_id        = one(oci_core_network_security_group.oke_worker[*].id)
  int_lb_nsg_id        = one(oci_core_network_security_group.oke_int_lb[*].id)
  pub_lb_nsg_id        = one(oci_core_network_security_group.oke_pub_lb[*].id)

  all_nsg_ids = {
    "cp"     = local.control_plane_nsg_id,
    "worker" = local.worker_nsg_id,
    "int_lb" = local.int_lb_nsg_id,
    "pub_lb" = local.pub_lb_nsg_id,
  }

  # Rules
  # https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-flannel-cni-publick8sapi_privateworkers_publiclb

  control_plane_ingress_rules = merge(
    {
      # Worker Nodes
      "Allow TCP ingress from worker nodes to Kubernetes API" : {
        protocol = local.tcp_protocol, port = local.apiserver_port, source = local.worker_nsg_id, source_type = local.rule_type_nsg,
      },
      "Allow TCP ingress from worker nodes to OKE control plane" : {
        protocol = local.tcp_protocol, port = local.oke_port, source = local.worker_nsg_id, source_type = local.rule_type_nsg,
      },
      # ICMP
      "Allow ICMP ingress from worker nodes for Path Discovery" : {
        protocol = local.icmp_protocol, source = local.worker_nsg_id, source_type = local.rule_type_nsg,
      },
    },
    # External Access
    { for allowed_cidr in var.cluster_endpoint_allowed_cidrs :
      "Allow TCP ingress to Kubernetes API from ${allowed_cidr}" => {
        protocol = local.tcp_protocol, port = local.apiserver_port, source = allowed_cidr, source_type = local.rule_type_cidr
      }
    }
  )

  control_plane_egress_rules = merge(
    {
      # Worker Nodes
      "Allow TCP egress from OKE control plane to all ports on worker nodes" : {
        protocol = local.tcp_protocol, port = local.all_ports, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      # OSN
      "Allow TCP egress from OKE control plane to all ports on OSN" : {
        protocol = local.tcp_protocol, port = local.all_ports, destination = local.osn, destination_type = local.rule_type_service,
      },
      # ICMP
      "Allow ICMP egress for Path Discovery to OSN" : {
        protocol = local.icmp_protocol, destination = local.osn, destination_type = local.rule_type_service,
      },
      "Allow ICMP egress for Path Discovery to worker nodes" : {
        protocol = local.icmp_protocol, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
    },
  )

  control_plane_rules = merge(
    local.control_plane_ingress_rules,
    local.control_plane_egress_rules,
    var.allow_rules_cp,
  )

  worker_ingress_rules = merge(
    {
      # Intra-Node
      "Allow ALL ingress for pod communication on worker nodes" : {
        protocol = local.all_protocols, port = local.all_ports, source = local.worker_nsg_id, source_type = local.rule_type_nsg,
      },
      # CP
      "Allow TCP ingress from OKE control plane to all ports on worker nodes" : {
        protocol = local.tcp_protocol, port = local.all_ports, source = local.control_plane_nsg_id, source_type = local.rule_type_nsg,
      },
      # LB
      "Allow TCP ingress from internal load balancers to node ports on worker nodes" : {
        protocol = local.tcp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, source = local.int_lb_nsg_id, source_type = local.rule_type_nsg,
      },
      "Allow UDP ingress from internal load balancers to node ports on worker nodes" : {
        protocol = local.udp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, source = local.int_lb_nsg_id, source_type = local.rule_type_nsg,
      },
      "Allow TCP ingress from internal load balancers to kube-proxy on worker nodes" : {
        protocol = local.tcp_protocol, port = local.kubeproxy_port, source = local.int_lb_nsg_id, source_type = local.rule_type_nsg,
      },
      # LB
      "Allow TCP ingress from public load balancers to node ports on worker nodes" : {
        protocol = local.tcp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, source = local.pub_lb_nsg_id, source_type = local.rule_type_nsg,
      },
      "Allow UDP ingress from public load balancers to node ports on worker nodes" : {
        protocol = local.udp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, source = local.pub_lb_nsg_id, source_type = local.rule_type_nsg,
      },
      "Allow TCP ingress from public load balancers to kube-proxy on worker nodes" : {
        protocol = local.tcp_protocol, port = local.kubeproxy_port, source = local.pub_lb_nsg_id, source_type = local.rule_type_nsg,
      },
      # ICMP
      "Allow ICMP ingress to workers for Path Discovery" : {
        protocol = local.icmp_protocol, port = local.all_ports, source = local.anywhere, source_type = local.rule_type_cidr,
      },
    },
  )

  worker_egress_rules = merge(
    {
      # Intra-Node
      "Allow ALL egress for pod communication on worker nodes" : {
        protocol = local.all_protocols, port = local.all_ports, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      # CP
      "Allow TCP egress from workers to Kubernetes API" : {
        protocol = local.tcp_protocol, port = local.apiserver_port, destination = local.control_plane_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow TCP egress from workers to OKE control plane" : {
        protocol = local.tcp_protocol, port = local.oke_port, destination = local.control_plane_nsg_id, destination_type = local.rule_type_nsg,
      },
      # OSN
      "Allow TCP egress from workers to all ports on OSN" : {
        protocol = local.tcp_protocol, port = local.all_ports, destination = local.osn, destination_type = local.rule_type_service,
      },
      # Internet
      "Allow ALL egress from workers to all ports on internet" : {
        protocol = local.all_protocols, port = local.all_ports, destination = local.anywhere, destination_type = local.rule_type_cidr,
      },
      # ICMP
      "Allow ICMP egress from workers for path discovery" : {
        protocol = local.icmp_protocol, port = local.all_ports, destination = local.anywhere, destination_type = local.rule_type_cidr,
      },
    },
  )

  worker_rules = merge(
    local.worker_ingress_rules,
    local.worker_egress_rules,
    var.allow_rules_workers,
  )

  int_lb_egress_rules = merge(
    {
      # Workers
      "Allow TCP egress from internal load balancers to nodes ports on workers" : {
        protocol = local.tcp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow UDP egress from internal load balancers to node ports on workers" : {
        protocol = local.udp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow TCP egress from internal load balancers to kube-proxy on workers " : {
        protocol = local.tcp_protocol, port = local.kubeproxy_port, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow UDP egress from internal load balancers to kube-proxy on workers " : {
        protocol = local.udp_protocol, port = local.kubeproxy_port, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
    },

  )

  int_lb_rules = merge(
    local.int_lb_egress_rules,
    var.allow_rules_internal_lb,
  )

  pub_lb_egress_rules = merge(
    {
      # Workers
      "Allow TCP egress from public load balancers to node ports on workers" : {
        protocol = local.tcp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow UDP egress from public load balancers to node ports on workers" : {
        protocol = local.udp_protocol, port_min = local.node_port_min, port_max = local.node_port_max, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow TCP egress from public load balancers to kube-proxy on workers" : {
        protocol = local.tcp_protocol, port = local.kubeproxy_port, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
      "Allow UDP egress from public load balancers to kube-proxy on workers" : {
        protocol = local.udp_protocol, port = local.kubeproxy_port, destination = local.worker_nsg_id, destination_type = local.rule_type_nsg,
      },
    },

  )

  pub_lb_rules = merge(
    local.pub_lb_egress_rules,
    var.allow_rules_public_lb,
  )

  rules_with_nsg = merge(
    { for k, v in local.control_plane_rules : k => merge(v, { "nsg_id" = local.control_plane_nsg_id }) },
    { for k, v in local.worker_rules : k => merge(v, { "nsg_id" = local.worker_nsg_id }) },
    { for k, v in local.int_lb_rules : k => merge(v, { "nsg_id" = local.int_lb_nsg_id }) },
    { for k, v in local.pub_lb_rules : k => merge(v, { "nsg_id" = local.pub_lb_nsg_id }) }
  )

  all_rules = { for k, v in local.rules_with_nsg : k => merge(v, {
    description               = k
    network_security_group_id = lookup(v, "nsg_id")
    direction                 = contains(keys(v), "source") ? "INGRESS" : "EGRESS"
    protocol                  = lookup(v, "protocol")
    source = (
      alltrue([
        upper(lookup(v, "source_type", "")) == local.rule_type_nsg,
      length(regexall("ocid\\d+\\.networksecuritygroup", lower(lookup(v, "source", "")))) == 0]) ?
      lookup(local.all_nsg_ids, lower(lookup(v, "source", "")), null) :
      lookup(v, "source", null)
    )
    source_type = lookup(v, "source_type", null)
    destination = (
      alltrue([
        upper(lookup(v, "destination_type", "")) == local.rule_type_nsg,
      length(regexall("ocid\\d+\\.networksecuritygroup", lower(lookup(v, "destination", "")))) == 0]) ?
      lookup(local.all_nsg_ids, lower(lookup(v, "destination", "")), null) :
      lookup(v, "destination", null)
    )
    destination_type = lookup(v, "destination_type", null)
  }) }

}

resource "oci_core_network_security_group" "oke_control_plane" {
  display_name   = "${var.cluster_name}-control-plane"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group" "oke_worker" {
  display_name   = "${var.cluster_name}-worker"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group" "oke_int_lb" {
  display_name   = "${var.cluster_name}-int-lb"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group" "oke_pub_lb" {
  display_name   = "${var.cluster_name}-pub-lb"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  freeform_tags  = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "oke" {
  for_each = local.all_rules

  description               = each.value.description
  network_security_group_id = each.value.network_security_group_id
  direction                 = each.value.direction
  protocol                  = each.value.protocol
  source                    = each.value.source
  source_type               = each.value.source_type
  destination               = each.value.destination
  destination_type          = each.value.destination_type

  dynamic "tcp_options" {
    for_each = (tostring(each.value.protocol) == tostring(local.tcp_protocol) &&
      tostring(each.value.direction) == "INGRESS" &&
      tonumber(lookup(each.value, "port", 0)) != local.all_ports ? [each.value] : []
    )
    content {
      destination_port_range {
        min = tonumber(lookup(tcp_options.value, "port_min", lookup(tcp_options.value, "port", 0)))
        max = tonumber(lookup(tcp_options.value, "port_max", lookup(tcp_options.value, "port", 0)))
      }
    }
  }

  dynamic "tcp_options" {
    for_each = (tostring(each.value.protocol) == tostring(local.tcp_protocol) &&
      tostring(each.value.direction) == "EGRESS" &&
      tonumber(lookup(each.value, "port", 0)) != local.all_ports ? [each.value] : []
    )
    content {
      destination_port_range {
        min = tonumber(lookup(tcp_options.value, "port_min", lookup(tcp_options.value, "port", 0)))
        max = tonumber(lookup(tcp_options.value, "port_max", lookup(tcp_options.value, "port", 0)))
      }
    }
  }

  dynamic "udp_options" {
    for_each = (tostring(each.value.protocol) == tostring(local.udp_protocol) &&
      tostring(each.value.direction) == "INGRESS" &&
      tonumber(lookup(each.value, "port", 0)) != local.all_ports ? [each.value] : []
    )
    content {
      destination_port_range {
        min = tonumber(lookup(udp_options.value, "port_min", lookup(udp_options.value, "port", 0)))
        max = tonumber(lookup(udp_options.value, "port_max", lookup(udp_options.value, "port", 0)))
      }
    }
  }

  dynamic "udp_options" {
    for_each = (tostring(each.value.protocol) == tostring(local.udp_protocol) &&
      tostring(each.value.direction) == "EGRESS" &&
      tonumber(lookup(each.value, "port", 0)) != local.all_ports ? [each.value] : []
    )
    content {
      destination_port_range {
        min = tonumber(lookup(udp_options.value, "port_min", lookup(udp_options.value, "port", 0)))
        max = tonumber(lookup(udp_options.value, "port_max", lookup(udp_options.value, "port", 0)))
      }
    }
  }

  dynamic "icmp_options" {
    for_each = tostring(each.value.protocol) == tostring(local.icmp_protocol) ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

}

output "nsg_ids" {
  description = "Created network security group IDs"
  value = local.all_nsg_ids
}
