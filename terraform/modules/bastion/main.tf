variable "project_slug" {}
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "key_name" {}
variable "allowed_ssh_cidr" {}
variable "ami_id" {}
variable "tags" { type = map(string) }

# Security group
resource "aws_security_group" "bastion_sg" {
  name   = "${var.project_slug}-bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Bastion EC2
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = merge(var.tags, {
  Name = "${var.project_slug}-bastion"
  Role = "bastion"
   })

}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "security_group_id" {
  value = aws_security_group.bastion_sg.id
}
