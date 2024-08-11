resource "digitalocean_volume_attachment" "domount" {
  droplet_id = digitalocean_droplet.dodroplet.id
  volume_id  = digitalocean_volume.dovolume.id
}
