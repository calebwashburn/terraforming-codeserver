output "ssh_private_key" {
  sensitive = true
  value     = "${tls_private_key.code_server.private_key_pem}"
}

output "public_ip" {
  value     = "${aws_eip.code_server.public_ip}"
}

output "dns_address" {
  value     = "${var.env_name}-code-server.${data.aws_route53_zone.selected.name}"
}

