output "api_endpoint" {
  value       = aws_apigatewayv2_api.api.api_endpoint
  description = "HTTP API base URL. Append /failover to trigger Lambda."
}
