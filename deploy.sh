#!/bin/bash
set -e

echo "=== STARTING DYNAMIC DEPLOYMENT ==="

# Get bastion IP from Terraform output
cd terraform
BASTION_IP=$(terraform output -raw bastion_public_ip)
cd ..

echo "Using bastion IP: ${BASTION_IP}"

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

echo "Ansible config updated with dynamic bastion IP"

# Run Ansible
cd ansible
echo "Starting Ansible deployment..."
ansible-playbook -i inventory.aws_ec2.yml playbook.yml

echo "=== DEPLOYMENT COMPLETE ==="
