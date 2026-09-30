# Terraform AWS Networking — README

Terraform configuration that provisions a two-AZ AWS VPC (public/private subnets, IGW, NAT), security groups, an Application Load Balancer with path-based routing, and two private EC2 instances (order-service, payment-service) reachable only through the ALB. This README covers how to deploy it, the resulting architecture, and proof that networking/routing/security work as intended.

---

## Contents

- [Contents of this folder](#contents-of-this-folder)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
  - [VPC & subnets](#vpc--subnets)
  - [Route tables](#route-tables)
  - [Security groups](#security-groups)
  - [Private-instance access](#private-instance-access)
- [Application Load Balancer](#application-load-balancer)
- [Deploy (PowerShell)](#deploy-powershell)
- [Verification & proof](#verification--proof)
- [Destroy / teardown](#destroy--teardown)
- [Git / CI precautions](#git--ci-precautions)
- [Troubleshooting](#troubleshooting)
- [Possible next steps](#possible-next-steps)

---

## Contents of this folder

- `*.tf` — Terraform configuration (VPC, subnets, IGW, NAT, route tables, security groups, ALB, target groups, EC2, SSM instance profile, outputs, variables, provider, versions)
- `terraform.tfvars` — variable values used for local testing (region, CIDRs, AZs, project/environment)
- `pictures_proof/` — screenshots proving connectivity/security/routing behavior (see [Verification & proof](#verification--proof))
- `terraform.tfstate` — (local) Terraform state created after apply. Do **NOT** commit this file to Git.

---

## Prerequisites

- Terraform (recommended >= 1.6)
- AWS CLI (optional but useful for verification; required for SSM Session Manager access)
- AWS credentials with sufficient permissions
- PowerShell on Windows (examples below use PowerShell)

Note: for CI/CD (GitHub Actions) use OIDC role assumption rather than long-lived access keys.

---

## Architecture

### VPC & subnets

Legend: IGW = Internet Gateway, NAT = NAT Gateway, ALB = Application Load Balancer, AZ = Availability Zone

```
AWS Region (ap-southeast-1)
  VPC 10.0.0.0/16   (terraform output vpc_id)
   |
   +-- AZ1 (ap-southeast-1a)
   |     +-- Public Subnet 1  (10.0.1.0/24)  -> route: 0.0.0.0/0 via IGW | hosts: NAT Gateway, ALB node
   |     +-- Private Subnet 1 (10.0.11.0/24) -> route: 0.0.0.0/0 via NAT | hosts: EC2 order-service (:8080)
   |
   +-- AZ2 (ap-southeast-1b)
   |     +-- Public Subnet 2  (10.0.2.0/24)  -> route: 0.0.0.0/0 via IGW | hosts: ALB node
   |     +-- Private Subnet 2 (10.0.12.0/24) -> route: 0.0.0.0/0 via NAT | hosts: EC2 payment-service (:8081)
   |
   +-- Internet Gateway (IGW) -- attached to the VPC, used by both public subnets
   +-- NAT Gateway -- deployed in Public Subnet 1 (AZ1), used by both private subnets
```

- EC2 instances in private subnets have no public IP and are therefore **not** directly reachable from the Internet.
- Private EC2 instances reach the Internet outbound through the NAT Gateway (source: [nat.tf](nat.tf)).

### Route tables

See [route_table.tf](route_table.tf):

| Route table | Rule | Associated subnets |
|---|---|---|
| `route_table_public` | `0.0.0.0/0 -> Internet Gateway` | Public Subnet 1, Public Subnet 2 |
| `route_table_private` | `0.0.0.0/0 -> NAT Gateway` (NAT lives in Public Subnet 1 / AZ1) | Private Subnet 1, Private Subnet 2 |

### Security groups

See [security_groups.tf](security_groups.tf):

| Security group | Inbound | Notes |
|---|---|---|
| `alb-sg` | 80/443 from `0.0.0.0/0` | only internet-facing edge; outbound all |
| `ec2-sg` | 8080-8081 **only from `alb-sg`**; 22 from `var.ssh_allowed_cidr` | never reachable from the internet directly; outbound all |
| `rds-sg` | 5432 (Postgres) only from `ec2-sg` | |
| `redis-sg` | 6379 (Redis) only from `ec2-sg` | |

> ⚠️ `ssh_allowed_cidr` defaults to `0.0.0.0/0` in [variables.tf](variables.tf) for lab convenience. Restrict it to your admin IP/CIDR in `terraform.tfvars` to follow least-privilege — the EC2 instances have no public IP today so this rule isn't internet-reachable, but the SG rule itself should still be scoped down.

### Private-instance access

There is **no bastion host** in this environment. EC2 instances have no public IP (`associate_public_ip_address = false`) and are administered via **AWS Systems Manager (SSM) Session Manager** (see `ssm_instance_profile.tf`), which avoids opening SSH to the instances at all.

```powershell
# From your workstation — no public IP or open SSH port required on the instance
aws ssm start-session --target <instance-id>
```

---

## Application Load Balancer

- ALB name: `vpc-lab-dev-alb`, internet-facing, deployed across both public subnets (AZ1 + AZ2) for multi-AZ availability.
- DNS name: printed by `terraform output alb_dns_name` after apply. Example from a prior run: `vpc-lab-dev-alb-546044212.ap-southeast-1.elb.amazonaws.com`.
- Listener: HTTP, port 80.

Path-based routing rules (see [alb.tf](alb.tf)):

| Priority | Path pattern | Target group | Forwards to |
|---|---|---|---|
| 100 | `/api/orders`, `/api/orders/*` | `order-tg` (port 8080) | EC2 order-service instance |
| 200 | `/api/payments`, `/api/payments/*` | `payment-tg` (port 8081) | EC2 payment-service instance |
| default | any other path | `order-tg` (port 8080) | listener's default action |

Target group health checks (see [target_groups.tf](target_groups.tf)):

| Target group | Health check path | Port |
|---|---|---|
| `order-tg` | `/api/orders/actuator/health` | traffic-port (8080) |
| `payment-tg` | `/api/payments/actuator/health` | traffic-port (8081) |

> Health check paths include each service's context path (`/api/orders`, `/api/payments`) instead of a bare `/actuator/health`, matching how the two Spring Boot services are actually exposed behind the ALB.

Verify routing manually:

```bash
curl -i http://<ALB_DNS_NAME>/api/orders
curl -i http://<ALB_DNS_NAME>/api/payments
```

---

## CloudWatch

- Attach CloudWatchAgentServerPolicy policy into role.
- Define Log Groups
- Define aws_ssm_parameter use templatefile (define in templates)

---

## S3 (File storage)
- One bucket shared by both services: `order/` and `payment/` prefixes
- Versioning: Enabled. Encryption: SSE-S3 (AES256). Public access: fully blocked (4/4 block settings).
- Bucket policy: deny any request that isn't over HTTPS (`aws:SecureTransport = false`).
- Lifecycle: STANDARD_IA_after `var.s3_glacier_transition_days` days, GLACIER after `var.s3_glacier_transition_days` days, noncurrent versions deleted after `var.s3_noncurrent_version_expiration_days` days
- IAM: the EC2 shared role (`microservices-ec2-role`) gets `s3:GetObject`/`PutObject`/`DeleteObject` scoped to only  `orders/*` and `payments/` - not `AmazonS3FullAccess`.


## Deploy (PowerShell)

1. Change into this folder:

```powershell
Set-Location "C:\Users\TaiDT9\Documents\jaka_base\jaka_aws_networking\terraform"
```

2. Set AWS credentials for the current session (temporary):

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

6. Inspect outputs:

```powershell
terraform output              # list all outputs
terraform output vpc_id
terraform output alb_dns_name
terraform output ec2_order_private_ip
terraform output ec2_payment_private_ip
```

---

## Verification & proof

### VPC / NAT — private EC2 reaches the Internet

Steps to reproduce and preserve proof that a private EC2 can reach the Internet via the NAT gateway:

1. Capture Terraform outputs after apply:

```powershell
terraform output > deploy_outputs.txt
```

2. Example outputs from a previous successful apply (kept here as reference):

- vpc_id: `vpc-0dec48674aa8d4de1`
- alb_dns_name: `vpc-lab-dev-alb-546044212.ap-southeast-1.elb.amazonaws.com`
- ec2_private_ip: `10.0.11.39`
- instance id: `i-08e5a95374996fd73`

(These values are from a prior apply recorded in the local state file — keep them as evidence in your run artifacts.)

3. Connect to the private EC2 via SSM Session Manager (no bastion needed):

```powershell
aws ssm start-session --target i-08e5a95374996fd73
```

4. Inside the private EC2, test outbound connectivity (ICMP may be blocked on some OS images — prefer a TCP/HTTP test):

```bash
nslookup google.com
curl -I https://www.google.com
# On Windows (PowerShell): Test-NetConnection -ComputerName google.com -Port 443
```

Expected result: `curl -I https://www.google.com` returns HTTP 200/302 headers. Save the terminal output as proof:

```powershell
curl -I https://www.google.com > nat_proof.txt
```

**Proof:** ![EC2 ping internet via NAT](pictures_proof/proof_ec2_ping_internet_via_nat.png)

### Security groups — reachability matrix

| Claim | Proof |
|---|---|
| EC2 can reach the ALB (port 8080 open, `ec2-sg` allows egress / `alb-sg` reachable) | ![EC2 ping ALB](pictures_proof/ec2_ping_alb_proof.png) |
| ALB can reach the Internet (port 80 open outbound) | ![ALB reach Internet](pictures_proof/alb_outbound_proof.png) |
| EC2 is **not** reachable from the Internet directly | No public IP is assigned (`associate_public_ip_address = false` in [ec2.tf](ec2.tf)), so there is no route from the internet to the instance regardless of SG rules. |

### ALB — routing & health

| Claim | Proof |
|---|---|
| Applications inside EC2 are reachable through the ALB DNS | ![Access via ALB DNS](pictures_proof/curl_ec2_health_check.png) |
| Target groups are healthy | ![Target group healthy](pictures_proof/target_group_healthy_proof.png) |
| Springboot App connect RDS | ![Springboot App connect RDS](pictures_proof/instances_asg_connect_rds_proof.png) |


### Elasticache
| Claim                 | Proof                                                     |
|---------------------- |-----------------------------------------------------------|
| redis-cli inside ec2  | ![redis-cli](pictures_proof/redis-cli-inside-ec2.png)     |
| app logs (rds + redis)| ![redis-cli](pictures_proof/ec2_logs_redis_rds_proof.png) |


### S3 — upload/download via EC2, presigned URL, versioning

1. Connect to EC2 via SSM (replace with the real instance id):

```powershell
aws ssm start-session --target i-xxxxxxxxxxxx
```

2. Inside the session, test upload/download (the EC2 role is only allowed on orders/*, payments/*):

```bash
echo "test receipt" > /tmp/receipt.txt
aws s3 cp /tmp/receipt.txt s3://<s3_bucket_name output>/orders/order-001/receipt.txt
aws s3 cp s3://<s3_bucket_name output>/orders/order-001/receipt.txt /tmp/receipt-downloaded.txt
cat /tmp/receipt-downloaded.txt
```

3. Verify access is denied outside the allowed prefixes (should fail — proves least-privilege works):

```bash
aws s3 cp /tmp/receipt.txt s3://<s3_bucket_name output>/uploads/should-fail.txt
# Expect: An error occurred (AccessDenied)
```

4. Verify versioning (upload the same key twice, list versions):

```bash
echo "v1" > /tmp/receipt.txt && aws s3 cp /tmp/receipt.txt s3://<bucket>/orders/order-001/receipt.txt
echo "v2" > /tmp/receipt.txt && aws s3 cp /tmp/receipt.txt s3://<bucket>/orders/order-001/receipt.txt
aws s3api list-object-versions --bucket <bucket> --prefix orders/order-001/receipt.txt
```

5. Generate a presigned URL (run from a machine with permissions, valid 30 min) and verify it downloads without AWS credentials:

```bash
aws s3 presign s3://<bucket>/orders/order-001/receipt.txt --expires-in 1800
curl -o receipt-via-presigned.txt "<generated url>"
```

| Claim | Proof |
|---|---|
| EC2 and S3 | ![ec2 - s3](pictures_proof/ec2_access_s3.png) |
| Versioning keeps both versions | ![ec2 - s3](pictures_proof/s3_versioning.png) |


---

## Destroy / teardown

From the same folder, after confirming you're using the correct AWS credentials:

```powershell
terraform destroy -var-file="terraform.tfvars" -auto-approve
```

After a successful destroy, you may remove local state files (only once you've confirmed resources are deleted):

```powershell
Remove-Item terraform.tfstate
Remove-Item terraform.tfstate.backup
Remove-Item -Recurse .terraform
```

---

## Git / CI precautions

- Add a `.gitignore`:

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

## Troubleshooting

- Region: check `terraform.tfvars` — the default region in this workspace is `ap-southeast-1`.
- If you do not see resources in the AWS console, confirm the console region matches the Terraform region.
- If `terraform plan` returns authentication errors (STS `GetCallerIdentity` failures), verify AWS credentials or role permissions.
- Consider configuring a remote state backend (S3 + DynamoDB) before enabling CI automated `apply`.

---

## Possible next steps

- Add a minimal `bastion` Terraform resource (optional — SSM Session Manager already covers private-instance access without one) and wire its SG.
- Add a GitHub Actions workflow that runs `terraform init/plan` on PRs and `terraform apply` on the protected branch with OIDC role assumption.
- Tighten `ssh_allowed_cidr` to a specific admin IP/CIDR instead of `0.0.0.0/0`.
- Add IAM roles/policies for the EC2 instances (CloudWatch logs, S3, Secrets Manager) per the Week 2 plan.
abling CI automated `apply`.

---

If you want, I can also:
- add a minimal `bastion` Terraform resource to this repo and wire the SGs
- create a basic GitHub Actions workflow that runs `terraform init/plan` on PRs and `terraform apply` on protected branch with OIDC role assumption

abling CI automated `apply`.

---

If you want, I can also:
- add a minimal `bastion` Terraform resource to this repo and wire the SGs
- create a basic GitHub Actions workflow that runs `terraform init/plan` on PRs and `terraform apply` on protected branch with OIDC role assumption

abling CI automated `apply`.

---

If you want, I can also:
- add a minimal `bastion` Terraform resource to this repo and wire the SGs
- create a basic GitHub Actions workflow that runs `terraform init/plan` on PRs and `terraform apply` on protected branch with OIDC role assumption

---

## Infra Diagram

```mermaid
flowchart TB
    Internet((Internet))
    Admin[Admin workstation]

    subgraph VPC["VPC 10.0.0.0/16 — vpc-lab-dev"]
        IGW[["Internet Gateway"]]
        RTPub[["Route Table: public\n0.0.0.0/0 → IGW\nlocal → 10.0.0.0/16 (implicit)"]]
        RTPriv[["Route Table: private\n0.0.0.0/0 → NAT\nlocal → 10.0.0.0/16 (implicit)"]]

        subgraph AZ1["AZ ap-southeast-1a"]
            subgraph Pub1["Public Subnet 1 — 10.0.1.0/24"]
                NAT[["NAT Gateway"]]
                ALB1["ALB node"]
            end
            subgraph Priv1["Private Subnet 1 — 10.0.11.0/24"]
                EC2Order["EC2: order-service\n:8080"]
            end
        end

        subgraph AZ2["AZ ap-southeast-1b"]
            subgraph Pub2["Public Subnet 2 — 10.0.2.0/24"]
                ALB2["ALB node"]
            end
            subgraph Priv2["Private Subnet 2 — 10.0.12.0/24"]
                EC2Payment["EC2: payment-service\n:8081"]
            end
        end

        RDSSG[("rds-sg\n5432 — no instance yet")]
        RedisSG[("redis-sg\n6379 — no instance yet")]
        IAMRole[["IAM role: app-role\n(CloudWatch Logs, S3, SSM,\nECR ReadOnly, CW Agent)"]]
        CWLogs[("CloudWatch Logs\n/microservice/order-service\n/microservice/payment-service")]
        SSMParam[("SSM Parameter Store\nCloudWatch Agent config")]
    end

    Pub1 -.associated with.-> RTPub
    Pub2 -.associated with.-> RTPub
    Priv1 -.associated with.-> RTPriv
    Priv2 -.associated with.-> RTPriv

    RTPub -->|"0.0.0.0/0"| IGW
    RTPriv -->|"0.0.0.0/0"| NAT

    Internet <-->|"80/443, inbound"| IGW
    IGW <-->|"80/443 (alb-sg)"| ALB1
    IGW <-->|"80/443 (alb-sg)"| ALB2
    NAT <-->|"0.0.0.0/0, outbound"| IGW
    IGW <-->|"0.0.0.0/0, outbound"| Internet

    ALB1 -->|"/api/orders → :8080\n(ec2-sg, local route — no IGW)"| EC2Order
    ALB2 -->|"/api/payments → :8081\n(ec2-sg, local route — no IGW)"| EC2Payment

    EC2Order -->|"egress via RTPriv"| NAT
    EC2Payment -->|"egress via RTPriv"| NAT

    EC2Order -.->|"5432 (sg ref)"| RDSSG
    EC2Payment -.->|"5432 (sg ref)"| RDSSG
    EC2Order -.->|"6379 (sg ref)"| RedisSG
    EC2Payment -.->|"6379 (sg ref)"| RedisSG

    EC2Order -.-> IAMRole
    EC2Payment -.-> IAMRole
    EC2Order -->|"agent logs/metrics"| CWLogs
    EC2Payment -->|"agent logs/metrics"| CWLogs
    EC2Order --> SSMParam
    EC2Payment --> SSMParam

    Admin -->|"ssm:StartSession\n(tag SSMAccess=true)"| EC2Order
    Admin -->|"ssm:StartSession\n(tag SSMAccess=true)"| EC2Payment
```

Notes:
- `rds-sg` / `redis-sg` are provisioned in [security_groups.tf](security_groups.tf) but no `aws_db_instance`/`aws_elasticache_cluster` exists yet — shown as reserved for future use.
- **The IGW is the gate for every packet crossing the VPC boundary — inbound to the ALB and outbound from the NAT alike.** It's not egress-only: an internet client's request to the ALB's public IP is delivered through the IGW (which 1:1 NATs the public IP to the ALB's private ENI) before it ever reaches the ALB.
- **ALB → EC2 is the one path that never touches the IGW**, because both live inside the same VPC — it matches the `local` route AWS adds implicitly to every route table for the VPC's CIDR (`10.0.0.0/16`). That route isn't shown in [route_table.tf](route_table.tf) because Terraform doesn't manage it; AWS injects it automatically, and it always wins over the `0.0.0.0/0` routes for any destination inside the VPC.
- Dotted lines denote security-group references or IAM role attachment (no live traffic); solid lines denote actual network/route paths.
- Admin access is via SSM Session Manager only — no SSH path exists into the private subnets from the Internet.

#########################################################################
| Claim           | Proof |
|---              |---|
| ASG             | ![ASG](pictures_proof/asg_instances_healthy.png) |
| CloudWatch Logs | ![Logs Groups](pictures_proof/cloudwatch_logs_group.png) |

## AWS Images
```
    data "aws_ami" "ubuntu" {

    }
```

```
    resource "aws_launch_template" "order_lt" {
        name_prefix   = "${local.name_prefix}-order-lt-"
        image_id      = data.aws_ami.ubuntu.id               # <---------------------------- ubunttu
        instance_type = var.instance_type

        iam_instance_profile {
            name = aws_iam_instance_profile.microservice_instance_profile.name
        }

        vpc_security_group_ids = [aws_security_group.ec2_sg.id]

        user_data = base64encode(templatefile("${path.module}/templates/service-bootstrap.sh.tpl", {
            region                = var.region
            ecr_registry          = local.ecr_registry
            image                 = local.order_image
            container_name        = "order-service"
            container_port        = aws_lb_target_group.order_tg.port
            db_username           = local.order_db_username
            db_url_param          = local.order_db_url_param
            db_password_param     = local.order_db_password_param
            cw_ssm_parameter_name = aws_ssm_parameter.order_service_agent_config.name
        }))

        tag_specifications {
                resource_type = "instance"
                tags = {
                Name      = "${local.name_prefix}-order"
                SSMAccess = "true"
            }
        }
    }
```

```
    resource "aws_autoscaling_group" "order_asg" {
        name = "${local.name_prefix}-order-asg"

        vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
        target_group_arns   = [aws_lb_target_group.order_tg.arn]

        health_check_type         = "ELB"
        health_check_grace_period = 120

        min_size         = var.asg_min_size
        max_size         = var.asg_max_size
        desired_capacity = var.asg_desired_capacity

        launch_template {
            id      = aws_launch_template.order_lt.id   # <----------------------- order_lt
            version = "$Latest"
        }

        instance_refresh {
            strategy = "Rolling"
            preferences {
            min_healthy_percentage = 50
            }
        }

        tag {
            key                 = "Name"
            value               = "${local.name_prefix}-order-asg"
            propagate_at_launch = true
        }

        tag {
            key                 = "SSMAccess"
            value               = "true"
            propagate_at_launch = true
        }
    }

```