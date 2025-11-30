variable "project_slug" {}
variable "tags" { type = map(string) }

# -------------------------
# Lambda Role
# -------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_slug}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_slug}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:*",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}
