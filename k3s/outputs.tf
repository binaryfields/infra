output "gateway_public_ip" {
  value = hcloud_server.gateway.ipv4_address
}

output "master_private_ips" {
  value = {
    for n in hcloud_server.master : n.name => [n.network[*].ip]
  }
}

output "node_private_ips" {
  value = {
    for n in hcloud_server.node : n.name => [n.network[*].ip]
  }
}
