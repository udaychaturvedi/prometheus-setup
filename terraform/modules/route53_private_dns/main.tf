resource "aws_route53_zone" "private_zone" {
  name = "${var.project_slug}.internal"
  comment = "Private hosted zone for Prometheus HA"
  force_destroy = false

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "prometheus" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "prometheus.${var.project_slug}.internal"
  type    = "A"
  ttl     = 60

  records = [var.primary_private_ip]
}
