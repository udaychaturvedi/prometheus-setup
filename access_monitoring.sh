#!/bin/bash
echo "🚀 Prometheus HA Setup Access Guide"
echo "==================================="

# Check if bastion file exists
if [ -f "ansible/group_vars/bastion_dynamic.yml" ]; then
    BASTION_IP=$(grep bastion_host ansible/group_vars/bastion_dynamic.yml | awk '{print $2}')
    echo "🔍 Bastion IP: $BASTION_IP"
else
    echo "❌ Bastion IP not found. Run Terraform first."
    exit 1
fi

echo ""
echo "📋 Access Methods:"
echo "1. SSH Tunnel:"
echo "   ssh -L 9090:PRIVATE_IP:9090 -L 9093:PRIVATE_IP:9093 ubuntu@$BASTION_IP"
echo ""
echo "2. Get private IPs:"
echo "   ansible -i ansible/inventory.aws_ec2.yml all --list-hosts"
echo ""
echo "3. Service URLs (after SSH tunnel):"
echo "   📊 Prometheus: http://localhost:9090"
echo "   🚨 Alertmanager: http://localhost:9093"
echo "   📈 Node Exporter: http://localhost:9100"
echo "   🔄 Nginx: http://localhost:9095"
