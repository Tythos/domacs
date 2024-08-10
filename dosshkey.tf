resource "digitalocean_ssh_key" "dosshkey" {
  name       = "dosshkey"
  public_key = tls_private_key.tlskey.public_key_openssh
}
