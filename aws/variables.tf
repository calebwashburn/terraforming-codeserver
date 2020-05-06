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
  default = "10.0.0.0/28"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/28"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "hosted_zone" {
  type    = string
}

variable "codeserver_version" {
  type    = string
  default = "3.2.0"
}

variable "go_version" {
  type    = string
  default = "1.14.2"
}

variable "acme_server_url"         {
  default = "https://acme-v02.api.letsencrypt.org/directory"
}
variable "acme_registration_email" {}


