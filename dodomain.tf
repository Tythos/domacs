resource "digitalocean_domain" "dodomain" {
  name       = var.DOMAIN_NAME
  ip_address = digitalocean_droplet.dodroplet.ipv4_address
}
