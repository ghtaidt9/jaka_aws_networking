#!/bin/bash
set -euo pipefail

dnf install -y amazon-cloudwatch-agent

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c ssm:${ssm_parameter_name} \
  -s
