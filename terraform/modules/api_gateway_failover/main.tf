# HTTP API Gateway -> Lambda Integration
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_slug}-failover-api"
  protocol_type = "HTTP"
  tags          = var.tags
}

# Fetch Lambda ARN
data "aws_lambda_function" "target" {
  function_name = var.lambda_name
}

# Integration (API -> Lambda)
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.aws_lambda_function.target.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route: POST /failover
resource "aws_apigatewayv2_route" "failover" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /failover"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Default stage ($default)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "${var.project_slug}-apigw-invoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.target.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
