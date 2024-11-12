resource "digitalocean_volume_attachment" "domount" {
  # will be attached as a block device (e.g., `/dev/sda`) but not yet mounted to the filesystem until corresponding cloud-init script is invoked
  droplet_id = digitalocean_droplet.dodroplet.id
  volume_id  = digitalocean_volume.dovolume.id
}
