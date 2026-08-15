# Terraform AWS Networking — README

This README explains how to deploy the AWS infrastructure in this folder with Terraform, what resources are created, a VPC diagram and explanations, and how to verify (and preserve proof) that an EC2 in the private subnet can reach the Internet through the NAT gateway.

---

## Contents of this folder

- `*.tf` — Terraform configuration files (VPC, subnets, IGW, NAT, route tables, security groups, ALB, EC2, outputs, variables, provider, versions)
- `terraform.tfvars` — variable values used for local testing (region, CIDRs, AZs, project/environment)
- `terraform.tfstate` — (local) Terraform state created after apply. Do NOT commit this file to Git.

---

## Prerequisites

- Terraform (recommended >= 1.6)
- AWS CLI (optional but useful for verification)
- AWS credentials with sufficient permissions (see notes below)
- PowerShell on Windows (examples shown for PowerShell)

Note: For CI/CD (GitHub Actions) use OIDC role assumption rather than long-lived access keys.

---

## Quick local deploy (PowerShell)

1. Open PowerShell and change into this folder:

```powershell
Set-Location "C:\Users\TaiDT9\Documents\jaka_base\jaka_aws_networking\terraform"
```

2. Set AWS environment variables for the current session (temporary):

```powershell
$env:AWS_ACCESS_KEY_ID = "<YOUR_ACCESS_KEY>"
$env:AWS_SECRET_ACCESS_KEY = "<YOUR_SECRET_KEY>"
$env:AWS_SESSION_TOKEN = "<YOUR_SESSION_TOKEN>"  # if using temporary creds
$env:AWS_REGION = "ap-southeast-1"
```

3. Initialize Terraform:

```powershell
terraform init
```

4. Validate and format:

```powershell
terraform fmt
terraform validate
```

5. Preview and apply:

```powershell
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
# or to skip interactive approval:
# terraform apply -var-file="terraform.tfvars" -auto-approve
```

6. After apply, inspect outputs:

```powershell
terraform output   # list all outputs
terraform output vpc_id
terraform output alb_dns_name
terraform output ec2_private_ip
```

---

## Recommended Git / CI precautions

- Add a `.gitignore` (examples):

```
.terraform/
*.tfstate
*.tfstate.*
crash.log
override.tf
override.tf.json
*.auto.tfvars
```

- Do NOT commit AWS credentials or local state files.
- Configure a remote backend (S3 + DynamoDB) for production state locking before using CI to run apply.
- Use OIDC/role assumption in GitHub Actions; avoid storing keys in Actions secrets if possible.

---

## Architecture diagram (logical)

Legend: IGW = Internet Gateway, NAT = NAT Gateway, ALB = Application Load Balancer

Public Subnet(s)                      Private Subnet(s)
+---------------------------+         +--------------------------+
|  Public Subnet 1          |         |  Private Subnet 1        |
|  - bastion (public IP)    | <---->  |  - EC2 app (no public IP)|
|  - NAT Gateway (EIP)      |  NAT    |  - private IP            |
|  - ALB (in public subnets)|         |  - routes -> NAT         |
+---------------------------+         +--------------------------+
           |                                   |
           +--------- Internet (via IGW) -------+

Route table summary:
- Public route table: 0.0.0.0/0 -> Internet Gateway (IGW)
- Private route table: 0.0.0.0/0 -> NAT Gateway (in a public subnet)

Security group summary:
- ALB SG: allow inbound 80/443 from 0.0.0.0/0, outbound to 0.0.0.0/0
- Bastion SG (if created): allow SSH (22) from your admin IP(s)
- EC2 SG: allow HTTP from ALB SG, allow SSH only from bastion SG or admin CIDR

---

## How this design affects connectivity

- EC2 instances in private subnets have no public IP and therefore are not directly reachable from the Internet.
- Private EC2 instances can reach the Internet for outbound traffic by using the NAT Gateway in the public subnet.
- To administer private EC2 instances you either:
  - connect through a bastion (jump host) in a public subnet, or
  - use AWS Systems Manager (SSM) Session Manager (preferred for reduced attack surface).

---

## Verifying EC2 outbound access via NAT (proof)

Steps to preserve a proof record that a private EC2 can reach the Internet via the NAT gateway:

1. Capture Terraform outputs (after apply):

```powershell
terraform output > deploy_outputs.txt
```

This will capture outputs produced by the `outputs.tf` file.

2. Example of outputs from a previous successful apply (saved here as reference):

- vpc_id: `vpc-0dec48674aa8d4de1`
- alb_dns_name: `vpc-lab-dev-alb-546044212.ap-southeast-1.elb.amazonaws.com`
- ec2_private_ip: `10.0.11.39`
- instance id: `i-08e5a95374996fd73`

(These values are from a prior apply recorded in the local state file — keep them as evidence in your run artifacts.)

3. Access the private EC2 to run the network test:

- If using a bastion host (recommended):
  - SSH to bastion (public IP) from your workstation.
  - From the bastion, SSH to the private EC2 using its private IP.

Example (from your laptop -> bastion -> private instance):

```bash
# on your laptop
ssh -i ~/.ssh/id_rsa ec2-user@<BASTION_PUBLIC_IP>
# on bastion
ssh -i ~/.ssh/id_rsa ec2-user@10.0.11.39
```

- If using SSM Session Manager:

```powershell
# From your workstation (no public IP on instance required)
aws ssm start-session --target i-08e5a95374996fd73
```

4. Inside the private EC2, test outbound connectivity (ICMP may be blocked on some OS images — prefer TCP test):

```bash
# Test DNS resolution
nslookup google.com
# Test HTTP(S)
curl -I https://www.google.com
# Or TCP connection to a known port (443)
# On Windows (PowerShell): Test-NetConnection -ComputerName google.com -Port 443
```

Expected result (example):

- `curl -I https://www.google.com` returns HTTP 200/302 headers
- `ping 8.8.8.8` may succeed depending on ICMP allowance, but HTTP test is more reliable

Save the terminal output as proof (e.g. `nat_proof.txt`).

```powershell
# from the bastion session or SSM session
curl -I https://www.google.com > nat_proof.txt
```

5. Keep the proof artifacts with your deployment logs (do NOT store secrets in those artifacts).

---

## How to remove everything (destroy)

From the same folder, after you verify you are using the correct AWS credentials:

```powershell
terraform destroy -var-file="terraform.tfvars" -auto-approve
```

That will read the state and delete the Terraform-managed resources. After successful destroy, you may remove local state files if desired (only after confirming resources are deleted):

```powershell
Remove-Item terraform.tfstate
Remove-Item terraform.tfstate.backup
Remove-Item -Recurse .terraform
```

---

## Notes and troubleshooting

- Region: check `terraform.tfvars` — the default region in this workspace is `ap-southeast-1`.
- If you do not see resources in the AWS console, confirm the console region matches the Terraform region.
- If `terraform plan` returns authentication errors (STS/GetCallerIdentity failures), verify AWS credentials or role permission.
- Consider configuring a remote state backend (S3 + DynamoDB) before enabling CI automated `apply`.

---

If you want, I can also:
- add a minimal `bastion` Terraform resource to this repo and wire the SGs
- create a basic GitHub Actions workflow that runs `terraform init/plan` on PRs and `terraform apply` on protected branch with OIDC role assumption

