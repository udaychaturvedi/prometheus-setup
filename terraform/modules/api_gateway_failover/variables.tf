variable "project_slug" {}

variable "lambda_name" {}

variable "tags" {
  type    = map(string)
  default = {}
}
