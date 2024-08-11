resource "digitalocean_project" "doproject" {
  name        = "domacs"
  description = "Namespace for encapsulation of cloud resources"
  purpose     = "Demonstration"
  environment = "Development"

  resources = [
    digitalocean_droplet.dodroplet.urn,
    digitalocean_domain.dodomain.urn,
    digitalocean_volume.dovolume.urn
  ]
}
