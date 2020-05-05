output "ssh_private_key" {
  sensitive = true
  value     = "${tls_private_key.code_server.private_key_pem}"
}

output "code_server_password" {
  sensitive = true
  value     = "${random_string.code_server_password.result}"
}

output "public_ip" {
  value     = "${aws_eip.code_server.public_ip}"
}

output "dns_address" {
  value     = "${var.env_name}-code-server.${var.hosted_zone}"
}

