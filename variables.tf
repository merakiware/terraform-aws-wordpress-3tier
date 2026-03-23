variable "ami" {
    type = string
    default = "ami-00f251754ac5da7f0"
}


# variables for VPC 

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "wpdv2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "3 AZs in this region to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# MariaDB variables
variable "DB_passwd" {
  description = "password for MariaDB"
  type = string
}
