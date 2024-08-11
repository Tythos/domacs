resource "digitalocean_volume_attachment" "domount" {
    # in this configuration, the volume will be mounted at `/mnt/dovolume`; we use 
  droplet_id = digitalocean_droplet.dodroplet.id
  volume_id  = digitalocean_volume.dovolume.id
}
