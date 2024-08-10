output "PRIVATE_SSH_KEY" {
  value     = tls_private_key.tlskey.private_key_pem
  sensitive = true
}

output "VM_IP_ADDR" {
  value = digitalocean_droplet.dodroplet.ipv4_address
}
