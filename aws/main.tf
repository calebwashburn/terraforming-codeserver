provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region

  version = "~> 2.7"
}

provider "tls" {
   version = "~> 2.0"
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
  private_ip             = var.private_ip

  user_data = templatefile("${path.module}/init.tmpl", { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"]})
  
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
  associate_with_private_ip = var.private_ip

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
