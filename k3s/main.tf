provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "private" {
  name     = var.cluster_name
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private.id
  network_zone = var.network_zone
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_network_route" "private_route_1" {
  network_id  = hcloud_network.private.id
  destination = "0.0.0.0/0"
  gateway     = var.gateway_private_ip
}

resource "hcloud_server" "gateway" {
  name = "${var.cluster_name}-gateway"

  server_type = var.gateway_type
  image       = var.gateway_image
  datacenter  = var.datacenter
  ssh_keys    = [var.ssh_key_name]
  user_data = templatefile(
    "${path.module}/templates/cloud/gateway.tftpl", {}
  )

  network {
    network_id = hcloud_network.private.id
    ip         = var.gateway_private_ip
  }

  firewall_ids = [hcloud_firewall.gateway_ssh_sg.id]

  depends_on = [hcloud_network_subnet.private_subnet]
}

resource "hcloud_server" "master" {
  count = var.master_count
  name  = "${var.cluster_name}-master-${count.index + 1}"

  server_type = var.master_type
  image       = var.instance_image
  datacenter  = var.datacenter
  ssh_keys    = [var.ssh_key_name]
  user_data = templatefile(
    "${path.module}/templates/cloud/private.tftpl",
    { private_interface = var.private_interface }
  )

  network {
    network_id = hcloud_network.private.id
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  depends_on = [
    hcloud_network_subnet.private_subnet,
    hcloud_server.gateway
  ]
}

resource "hcloud_server" "node" {
  count = var.node_count
  name  = "${var.cluster_name}-node-${count.index + 1}"

  server_type = var.node_type
  image       = var.instance_image
  datacenter  = var.datacenter
  ssh_keys    = [var.ssh_key_name]
  user_data = templatefile(
    "${path.module}/templates/cloud/private.tftpl",
    { private_interface = var.private_interface }
  )

  network {
    network_id = hcloud_network.private.id
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  depends_on = [
    hcloud_network_subnet.private_subnet,
    hcloud_server.gateway
  ]
}

resource "hcloud_volume" "node_data" {
  count     = var.node_count
  name      = "${var.cluster_name}-node-data-${count.index + 1}"

  size      = var.node_volume_size
  format    = "xfs"
  location = var.location
}

resource "hcloud_volume_attachment" "node_data" {
  count     = var.node_count

  volume_id = hcloud_volume.node_data[count.index].id
  server_id = hcloud_server.node[count.index].id
}

resource "hcloud_firewall" "gateway_ssh_sg" {
  name = "${var.cluster_name}-gateway-ssh"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0"]
  }
}
