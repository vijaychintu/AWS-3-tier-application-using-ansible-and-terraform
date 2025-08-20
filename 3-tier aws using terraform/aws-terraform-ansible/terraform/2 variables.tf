variable "name" {
  type    = string
  default = "tf-ansible-demo"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "enable_rds" {
  type    = bool
  default = false
}

# Only used if enable_rds = true
variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type    = string
  default = "AppUser!234"
}

variable "vpc_id" {
  description = "The ID of the VPC to create resources in."
  type        = string
}
