output "private_zone_id" {
  value = aws_route53_zone.private_zone.zone_id
}

output "prometheus_record_fqdn" {
  value = aws_route53_record.prometheus.fqdn
}
