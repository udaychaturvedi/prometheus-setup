variable "project_slug" {}
variable "primary_ip" {}
variable "standby_ip" {}
variable "lambda_role_arn" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "tags" { type = map(string) }

# Make these optional for initial creation
variable "zone_id" {
  type    = string
  default = ""
}

variable "record_name" {
  type    = string  
  default = ""
}
