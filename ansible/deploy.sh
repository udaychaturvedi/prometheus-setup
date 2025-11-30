#!/bin/bash
set -e

# Get bastion IP from Terraform output
cd terraform
BASTION_IP=$(terraform output -raw bastion_public_ip)
cd ..

# Update ansible.cfg with dynamic bastion IP
cat > ansible/ansible.cfg << CONFIG
[defaults]
host_key_checking = False
inventory = inventory.aws_ec2.yml
private_key_file = ~/.ssh/prometheus.pem
remote_user = ubuntu
timeout = 30

[ssh_connection]
ssh_args = -o ProxyCommand="ssh -W %h:%p -q ubuntu@${BASTION_IP}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
control_path = ~/.ssh/ansible-%%r@%%h:%%p
pipelining = True
CONFIG

echo "Using bastion IP: ${BASTION_IP}"

# Run Ansible
cd ansible
ansible-playbook -i inventory.aws_ec2.yml playbook.yml
