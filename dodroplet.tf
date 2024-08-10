resource "digitalocean_droplet" "dodroplet" {
  image     = "ubuntu-22-04-x64"
  name      = "dodroplet"
  region    = "sfo3"
  size      = "s-4vcpu-8gb"
  ssh_keys  = [digitalocean_ssh_key.dosshkey.id]
  user_data = file("user_data.yaml")
}
