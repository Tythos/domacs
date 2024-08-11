variable "DO_TOKEN" {
  type        = string
  description = "API token for deployment of DigitalOcean resources"
}

variable "DOMAIN_NAME" {
  type        = string
  description = "Managed domain name (should point to DigitalOcean NS records) used by the VM"
}

variable "ADMIN_USER" {
  type        = string
  description = "Name of user who will initially be able to connect to the server (e.g., before other whitelist names are added)"
}

variable "ADMIN_UUID" {
  type        = string
  description = "UUID of user who will initially be able to connect to the server (see https://mcuuid.net for easy lookup)"
}

variable "DO_REGION" {
  type        = string
  description = "DigitalOcean region into which resources will be deployed"
}
