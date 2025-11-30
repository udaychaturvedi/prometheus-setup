variable "zone_id" {}
variable "record_name" {}
variable "project_slug" {}
variable "primary_ip" {}
variable "standby_ip" {}
variable "lambda_role_arn" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "tags" { type = map(string) }

resource "aws_lambda_function" "failover" {
  function_name = "${var.project_slug}-failover"
  role          = var.lambda_role_arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10

  filename         = "${path.module}/lambda_failover.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_failover.zip")

  environment {
    variables = {
      ZONE_ID     = var.zone_id
      RECORD_NAME = var.record_name
      STANDBY_IP  = var.standby_ip
    }
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }

  tags     = {}
  tags_all = {}
}

output "lambda_name" {
  value = aws_lambda_function.failover.function_name
}
