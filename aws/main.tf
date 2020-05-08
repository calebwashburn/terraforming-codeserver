provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region

  version = "~> 2.7"
}

provider "tls" {
   version = "~> 2.0"
}

provider "random" {
  version = "~> 2.2.0"
}

provider "acme" {
  version = "~> 1.5"
  server_url = var.acme_server_url
}

terraform {
  required_version = "> 0.12.0"
}

data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create an on the fly private key for the registration 
# (not the certificate). Could simply be imported as well
resource "tls_private_key" "acme_registration_private_key" {
  algorithm = "RSA"
}

# Set up a registration using the registration private key
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.acme_registration_private_key.private_key_pem
  email_address   = var.acme_registration_email
}

# Create a certificate
resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "${var.env_name}-code-server.${var.hosted_zone}"
  
  dns_challenge {
    provider = "route53"
  }
}

resource "random_string" "code_server_password" {
  length  = 16
  special = false
}

resource "tls_private_key" "code_server" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "code_server" {
  key_name   = "${var.env_name}-code-server-key"
  public_key = tls_private_key.code_server.public_key_openssh
}

# Create a VPC
resource "aws_vpc" "vpc" {
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  cidr_block = var.vpc_cidr

  tags = {
      Name = "${var.env_name}-code-server-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
      Name = "${var.env_name}-code-server-ig"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  depends_on = [aws_internet_gateway.gw]
}

# Create a Subnet
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.env_name}-code-server-subnet"
  }
}

resource "aws_route_table_association" "route_subnets" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "code_server_security_group" {
  name        = "code_server_security_group"
  description = "Code Server Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = "${var.env_name}-code-server-sg"
  }
}

resource "aws_instance" "code_server" {
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.code_server.key_name
  vpc_security_group_ids = ["${aws_security_group.code_server_security_group.id}"]
  source_dest_check      = false
  subnet_id              = aws_subnet.subnet.id


  user_data = templatefile("${path.module}/init.tmpl", { 
    HOST_NAME = "${var.env_name}-code-server.${var.hosted_zone}", 
    GO_VERSION = "${var.go_version}",
    GO_VSCODE_VERSION = "${var.go_vscode_version}",
    CODESERVER_VERSION = "${var.codeserver_version}",
    CODESERVER_PASSWORD = "${random_string.code_server_password.result}",
    CODESERVER_PRIVATEKEY = "${acme_certificate.certificate.private_key_pem}",
    CODESERVER_CERTIFICATE = "${acme_certificate.certificate.certificate_pem}"
  })
  
  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  tags = {
    Name = "${var.env_name}-code-server"
  }
}

resource "aws_eip" "code_server" {
  instance = aws_instance.code_server.id
  vpc      = true

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.env_name}-code-server-eip"
  }
}

data "aws_route53_zone" "selected" {
  name         = "cwashburn.io."
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.env_name}-code-server.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_eip.code_server.public_ip}"]
}
