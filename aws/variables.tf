variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "region" {
  default = ""
}

variable "env_name" {}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "private_ip" {
  type    = string
  default = "10.0.0.12"
}