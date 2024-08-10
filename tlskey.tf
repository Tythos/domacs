resource "tls_private_key" "tlskey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
