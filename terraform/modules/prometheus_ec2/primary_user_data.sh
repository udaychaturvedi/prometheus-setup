#!/bin/bash
mkdir -p /home/ubuntu/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDahWp2OuMExh3t8BCarnemYA2y+QvFvGCGsaHEp2uHFjAokclz37z9h0KotHhr870xOytxmNhuqQUboAqQlNc75QAtQDBtiQuOuBnLKd8xgv/TzZwPdmZDAU9DZD7XURumPoxSl0b4FH2XwWGh+/gX5BDIQUmLmAG/eOx+YgV+XA+zgm9sX9WYkJ654Vs0m73SsckzunxdpdeswBIdgRfC7zXqfUHOEBM/MqhJI4RHN+cBE4WJtxAT6czkXR1N4G2amBa8tMzcaVmG+Fan/+bPivAGHbogFHk0cfu9z3e+ed+W1O5rBnU5A3pIQ/W9ZMQcgRq4UDb6127dw6IdbGRz" >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
