variable "project_slug" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "tags" { type = map(string) }

resource "aws_security_group" "prometheus_sg" {
  name        = "${var.project_slug}-prom-sg"
  description = "Prometheus SG"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "Alertmanager"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

##############################
# PRIMARY NODE
##############################

resource "aws_instance" "primary" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.prometheus_sg.id]
  key_name               = var.key_name

  user_data = file("${path.module}/primary_user_data.sh")

  tags = merge(var.tags, {
    Name = "${var.project_slug}-primary"
    Role = "prometheus_primary"
  })
}

##############################
# STANDBY NODE
##############################

resource "aws_instance" "standby" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets[1]
  vpc_security_group_ids = [aws_security_group.prometheus_sg.id]
  key_name               = var.key_name

  user_data = file("${path.module}/standby_user_data.sh")

  tags = merge(var.tags, {
    Name = "${var.project_slug}-standby"
    Role = "prometheus_standby"
  })
}

##############################
# OUTPUTS
##############################

output "primary_private_ip" {
  value = aws_instance.primary.private_ip
}

output "standby_private_ip" {
  value = aws_instance.standby.private_ip
}
