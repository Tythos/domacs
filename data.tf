data "template_file" "user_data_yaml" {
  template = file("${path.module}/user_data.yaml.tpl")

  vars = {
    ADMIN_USER = var.ADMIN_USER
    ADMIN_UUID = var.ADMIN_UUID
    PERSISTENT_VOLUME_PATH = "/mnt/${digitalocean_volume.dovolume.name}/minecraft"
  }
}
