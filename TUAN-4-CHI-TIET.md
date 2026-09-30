# Tuần 4 chi tiết — S3, ECR & Full Production Deployment

## Bối Cảnh & Mục Tiêu

**Tuần 1-3 đã hoàn thành:**
- ✅ Local Docker (5 containers)
- ✅ AWS Networking (VPC, ALB, security groups)
- ✅ AWS Compute & Database (EC2, RDS, ElastiCache)

**Tuần 4 mục tiêu:**
- Deploy Spring Boot Docker images lên ECR (Elastic Container Registry)
- Setup S3 buckets cho file storage (documents, images)
- Connect EC2 → S3 (upload/download files)
- Setup CloudWatch monitoring + logging
- Full end-to-end testing: User → ALB → EC2 → RDS + S3
- Production-ready microservices architecture

---

## Tại Sao Cần Tuần 4?

```
Tuần 3 problematic:
  EC2 chỉ chạy Docker, nhưng image ở đâu?
  ❌ Chỉ có local image, EC2 không có
  ❌ Mỗi EC2 cần build image từ source (slow!)
  
Tuần 4 solution:
  ECR (Docker Registry on AWS):
    ✅ Push image từ laptop → ECR
    ✅ EC2 pull image từ ECR (fast, private)
    ✅ Auto Scaling Group dùng chung image (centralized)

File storage:
  Local Docker → files stored inside container ❌
  Production → S3 bucket ✅ (durable, scalable)
  
Full stack:
  Internet → ALB → EC2 → RDS (data) + S3 (files) + ElastiCache (cache)
```

---

## Chủ Đề 1: ECR (Elastic Container Registry)

### Nội Dung Phải Học

- **ECR là gì**: Private Docker registry trên AWS (như Docker Hub nhưng private)
- **Repository**: Nơi lưu Docker images (order-service, payment-service, etc.)
- **Image Tags**: Version management (v1, v2, latest, prod, staging)
- **Image Scanning**: Scan image cho security vulnerabilities (optional nhưng recommended)
- **Lifecycle Policies**: Auto delete old images để tiết kiệm storage
- **IAM Permissions**: EC2 role cần push/pull permission từ ECR
- **Docker Login**: Cách authenticate tới ECR (`aws ecr get-login-password`)

### Workflow

```
Developer Machine:
  1. Build image locally: docker build -t order-service:v1 .
  2. Tag cho ECR: docker tag order-service:v1 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:v1
  3. Push tới ECR: docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:v1

AWS ECR:
  ├─ Repository: order-service
  │   ├─ Image: v1 (size: 250MB, scan: PASSED)
  │   ├─ Image: v2 (size: 255MB, scan: PASSED)
  │   └─ Image: latest (alias to v2)
  │
  └─ Repository: payment-service
      ├─ Image: v1
      └─ Image: latest

EC2 (tuần 3):
  1. EC2 IAM role có ECR pull permission
  2. User data script: docker pull 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
  3. Run: docker run ... [image from ECR]
```

**Output cụ thể:**
- Tạo 2 ECR repositories (order-service, payment-service)
- Push Docker images từ laptop → ECR
- Cấu hình image scanning
- Cấu hình lifecycle policy (keep last 10 images)
- Chứng minh:
  - `docker push` successful
  - Image appear trong ECR console
  - EC2 có thể pull image từ ECR (via IAM role)
  - Image tag versioning (v1, v2, latest)
- Ghi vào README: ECR registry URL, push/pull commands

---

## Chủ Đề 2: S3 (Simple Storage Service)

### Nội Dung Phải Học

- **S3 là gì**: Object storage service (unlimited scale, 99.99% durability)
- **Buckets**: Container cho objects (như thư mục ở máy bạn)
  - Bucket name globally unique (ví dụ: my-company-microservices-prod)
  - Region-specific (us-east-1, eu-west-1, etc.)
- **Objects**: File được lưu trong bucket (ví dụ: orders/order-123/receipt.pdf)
- **Versioning**: Keep multiple versions của file (rollback nếu cần)
- **Access Control**:
  - **Public**: Anyone có URL có thể download (dangerous!)
  - **Private**: Chỉ authenticated users via IAM
  - **Presigned URLs**: Temporary access (30 min) để download file
- **Encryption**:
  - **At rest**: SSE-S3 (server-side encryption) mặc định
  - **In transit**: HTTPS only (block unencrypted)
- **Lifecycle Policies**: Auto move old objects tới Glacier (cheaper long-term storage)

### Cấu Trúc S3 Tiêu Chuẩn

```
S3 Bucket: microservices-prod
  ├─ orders/
  │   ├─ order-001/
  │   │   ├─ receipt.pdf (uploaded by order-service)
  │   │   ├─ invoice.pdf
  │   │   └─ metadata.json
  │   └─ order-002/
  │       └─ receipt.pdf
  │
  ├─ payments/
  │   ├─ payment-001/
  │   │   ├─ confirmation.pdf
  │   │   └─ receipt.json
  │   └─ payment-002/
  │
  └─ uploads/
      ├─ product-images/
      │   ├─ prod-001.jpg
      │   └─ prod-002.jpg
      └─ user-documents/
          ├─ user-123-passport.pdf
          └─ user-124-idcard.pdf

Bucket Policy:
  - Private by default (block all public)
  - EC2 instances có S3 IAM permission
  - Presigned URLs cho user download (temporary access)
```

**Spring Boot Integration:**

```java
@Configuration
public class S3Config {
    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
            .region(Region.US_EAST_1)
            .build();
    }
}

@Service
public class OrderService {
    private S3Client s3Client;
    
    public String uploadOrderReceipt(Long orderId, byte[] pdfData) {
        String key = "orders/order-" + orderId + "/receipt.pdf";
        
        s3Client.putObject(request -> request
            .bucket("microservices-prod")
            .key(key)
            .build(),
            RequestBody.fromBytes(pdfData));
        
        return generatePresignedUrl(key);
    }
    
    private String generatePresignedUrl(String key) {
        // Returns URL valid for 30 minutes
        // User can download file without AWS credentials
    }
}
```

**Output cụ thể:**
- Tạo 1 S3 bucket (private, encryption enabled)
- Cấu hình versioning
- Cấu hình lifecycle policies
- Cấu hình bucket policy (EC2 can put/get objects)
- Chứng minh:
  - EC2 upload file tới S3
  - EC2 download file từ S3
  - Generate presigned URLs
  - File accessible via presigned URL (30 min valid)
  - Versioning works (upload same key twice, both versions stored)
- Ghi vào README: S3 bucket name, IAM policy, usage examples

---

## Chủ Đề 3: CloudWatch Monitoring & Logging

### Nội Dung Phải Học

- **CloudWatch Logs**: Centralized logging (collect logs từ EC2, RDS, ALB)
- **Log Groups**: Container cho logs từ một service (ví dụ: /aws/ec2/order-service)
- **Log Streams**: Logs từ một instance (ví dụ: order-service-i-12345)
- **CloudWatch Metrics**: Monitor CPU, memory, network (EC2, RDS, ALB)
- **Alarms**: Alert khi metric vượt ngưỡng (ví dụ: CPU > 80%)
- **Dashboards**: Visualize metrics + logs
- **Retention Policy**: Auto delete logs sau N days (cost optimization)

### Monitoring Setup

```
EC2 Instance (order-service):
  ├─ CloudWatch Agent installed
  ├─ Collect:
  │   ├─ CPU usage
  │   ├─ Memory usage
  │   ├─ Disk I/O
  │   └─ Network traffic
  └─ Send to CloudWatch every 60s

Spring Boot Application:
  ├─ Spring Boot Actuator metrics
  │   ├─ HTTP request count
  │   ├─ HTTP request latency
  │   ├─ Database connection pool size
  │   └─ Cache hit ratio
  └─ Send to CloudWatch via Micrometer

RDS Instance (order-db):
  ├─ Native RDS metrics:
  │   ├─ CPU %
  │   ├─ Database connections
  │   ├─ Storage used
  │   ├─ Replication lag (multi-AZ)
  │   └─ Read/Write latency
  └─ CloudWatch auto collect

ALB:
  ├─ Request count
  ├─ Request latency
  ├─ HTTP 4xx/5xx errors
  ├─ Active connection count
  └─ Target health status
```

**Alarms Setup:**

```
Alarm 1: High CPU (order-service EC2)
  ├─ Threshold: CPU > 70% for 5 minutes
  └─ Action: SNS notification (send email to ops team)

Alarm 2: Database connection pool exhaustion
  ├─ Threshold: Active connections > 90%
  └─ Action: Trigger auto-scaling (add more EC2 instances)

Alarm 3: ALB unhealthy targets
  ├─ Threshold: Unhealthy target count > 0
  └─ Action: Page on-call engineer (PagerDuty integration)

Alarm 4: RDS replication lag > 1s
  ├─ Threshold: Replication lag > 1000ms
  └─ Action: Investigation alert (multi-AZ failover might be happening)
```

**Output cụ thể:**
- Setup CloudWatch agent trên EC2 instances
- Create log groups + streams
- Create custom metrics (request latency, cache hit rate)
- Create alarms (high CPU, connection pool, errors)
- Create dashboard (visualize all metrics)
- Chứng minh:
  - Logs từ EC2 appear trong CloudWatch
  - Metrics từ RDS appear
  - Metrics từ ALB appear
  - Generate load test → see metrics spike
  - Alarm triggers → email notification
- Ghi vào README: CloudWatch log group names, metrics, alarms

---

## Chủ Đề 4: End-to-End Production Deployment

### Nội Dung Phải Học

- **Deployment Checklist**: Các bước trước khi go-live
- **Smoke Tests**: Quick tests để verify basic functionality
- **Load Testing**: Verify system handles expected traffic
- **Rollback Plan**: Nếu có issue, cách rollback
- **Runbook**: Documented procedures cho incident response
- **CI/CD Pipeline** (preview, full tuần sau):
  - Code push → GitHub
  - GitHub Actions build Docker image
  - Push image tới ECR
  - Trigger EC2 auto-scaling to pull new image
  - Rolling update (0 downtime)

### Deployment Flow

```
Day of Deployment:

1. Pre-deployment (1 day before):
   ├─ Run smoke tests in staging environment
   ├─ Load test with expected traffic
   ├─ Verify backups (RDS snapshots, S3 versioning)
   └─ Notify team via Slack

2. Deployment (production):
   ├─ Push Docker images tới ECR (tag: v1.0.0)
   ├─ Update Launch Template (new image version)
   ├─ Terminate 1 EC2 instance (ASG launches replacement with new image)
   ├─ Monitor CloudWatch metrics + logs
   ├─ Verify no errors in logs
   ├─ Repeat for next instance
   └─ Rolling update complete (0 downtime)

3. Post-deployment:
   ├─ Verify all metrics normal
   ├─ Run smoke tests again
   ├─ Monitor for 1 hour
   └─ Document deployment in runbook
```

**Smoke Tests Example:**

```bash
#!/bin/bash

ALB_DNS="order-payment-alb.us-east-1.elb.amazonaws.com"

# Test 1: ALB is reachable
echo "Test 1: ALB health..."
curl -f http://$ALB_DNS/health || exit 1

# Test 2: Order API works
echo "Test 2: Create order..."
ORDER_ID=$(curl -s -X POST http://$ALB_DNS/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId":"test","productSku":"TEST-001","quantity":1,"totalAmount":99.99}' \
  | jq '.id')
[ ! -z "$ORDER_ID" ] || exit 1

# Test 3: Payment API works
echo "Test 3: Create payment..."
curl -f -X POST http://$ALB_DNS/api/payments \
  -H "Content-Type: application/json" \
  -d "{\"orderId\":$ORDER_ID,\"customerId\":\"test\",\"amount\":99.99,\"paymentMethod\":\"CREDIT_CARD\"}" \
  || exit 1

# Test 4: Database accessible
echo "Test 4: Query database..."
docker exec $(docker ps | grep order-db | awk '{print $1}') \
  psql -U postgres -d order_db -c "SELECT COUNT(*) FROM orders WHERE id = $ORDER_ID;" \
  || exit 1

echo "✅ All smoke tests passed!"
```

**Output cụ thể:**
- Deployment script (update launch template, trigger ASG)
- Smoke test script (verify all APIs work)
- Rollback script (revert to previous image version)
- Runbook (incident response procedures)
- Chứng minh:
  - Deploy new Docker image version
  - Smoke tests pass
  - Zero downtime (ALB still serving traffic)
  - Rollback if needed
- Ghi vào README: deployment steps, smoke tests, rollback procedure

---

## Chủ Đề 5: Secrets Management

### Nội Dung Phải Học

- **Secrets Manager vs Parameter Store**:
  - **Secrets Manager**: Better for sensitive data (database passwords, API keys)
  - **Parameter Store**: Better for config values (feature flags, endpoints)
- **Rotation**: Auto-rotate secrets (ví dụ: DB password mỗi 30 days)
- **Encryption**: Secrets encrypted at rest (KMS key)
- **Access Control**: Only microservices cần access có IAM permission

### Secrets Setup

```
AWS Secrets Manager:
  ├─ Secret: prod/order-db/password
  │   ├─ Value: (auto-rotated every 30 days)
  │   ├─ Encryption: KMS key
  │   └─ Access: order-service EC2 role only
  │
  ├─ Secret: prod/payment-db/password
  │   └─ Access: payment-service EC2 role only
  │
  ├─ Secret: prod/api-keys
  │   ├─ stripe_key: sk_live_xxxxx
  │   ├─ slack_webhook: https://hooks.slack.com/xxxxx
  │   └─ Access: order-service + payment-service
  │
  └─ Secret: prod/ssl-certificate
      ├─ Value: (PEM format)
      └─ Rotation: yearly manual

AWS Parameter Store:
  ├─ Parameter: /prod/order-service/replica-count
  │   ├─ Value: 2
  │   └─ Type: String
  │
  ├─ Parameter: /prod/feature-flags/enable-new-ui
  │   ├─ Value: true
  │   └─ Type: String
  │
  └─ Parameter: /prod/redis-endpoint
      ├─ Value: order-payment-cache.xxxxx.cache.amazonaws.com
      └─ Type: String
```

**Spring Boot Integration:**

```yaml
# application-prod.yml
spring:
  datasource:
    url: jdbc:postgresql://order-db.xxxxx.rds.amazonaws.com:5432/order_db?sslmode=require
    username: postgres
    password: ${DB_PASSWORD}  # From Secrets Manager via AWS SDK

management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus  # CloudWatch scrape these
```

**Output cụ thể:**
- Create secrets dalam Secrets Manager
- Create parameters dalam Parameter Store
- Cấu hình Spring Boot để read từ Secrets Manager
- Chứng minh:
  - Application can read secrets without hardcoding
  - Secrets rotation works
  - Only authorized services can access
- Ghi vào README: secrets management strategy

---

## Portfolio Cuối Tháng 1 — Repo `springboot-aws-production`

Cấu trúc thư mục:
```
springboot-aws-production/
├── terraform/
│   ├── ecr.tf                    # ECR repositories
│   ├── s3.tf                     # S3 buckets
│   ├── cloudwatch.tf             # Log groups, alarms, dashboards
│   ├── secrets-manager.tf        # Secrets + parameters
│   └── outputs.tf
│
├── scripts/
│   ├── build-and-push.sh         # Build Docker image, push to ECR
│   ├── deploy.sh                 # Deploy (update launch template, trigger ASG)
│   ├── smoke-tests.sh            # Verify deployment
│   ├── rollback.sh               # Rollback previous version
│   └── load-test.sh              # Generate traffic for load testing
│
├── docker/
│   ├── order-service/
│   │   ├── Dockerfile (multi-stage)
│   │   └── .dockerignore
│   └─── payment-service/
│       ├── Dockerfile (multi-stage)
│       └── .dockerignore
│
├── docs/
│   ├── RUNBOOK.md                # Incident response procedures
│   ├── DEPLOYMENT.md             # Step-by-step deployment guide
│   ├── ROLLBACK.md               # Rollback procedures
│   └── TROUBLESHOOTING.md        # Common issues + fixes
│
├── diagrams/
│   ├── production-architecture.png   # Full stack diagram
│   ├── data-flow.png                # User → ALB → EC2 → RDS/S3
│   ├── cloudwatch-dashboard.png     # Monitoring setup
│   └── disaster-recovery.png        # Backup + failover strategy
│
└── README.md
```

**README.md phải trả lời được:**

1. **Repo này chứng minh năng lực gì?**
   - Deploy Spring Boot microservices lên AWS (full stack)
   - Setup Docker image registry (ECR)
   - File storage (S3)
   - Monitoring & logging (CloudWatch)
   - Secrets management
   - Production-ready deployment

2. **Full Architecture:**
   ```
   Internet
      ↓ (HTTP)
   ALB (public subnet)
      ↓ (Java app, 8080/8081)
   EC2 instances (private subnet, Auto Scaling Group)
      ├─ RDS (order-db + payment-db, multi-AZ)
      ├─ S3 (file storage)
      ├─ ElastiCache (Redis)
      └─ CloudWatch (logs + metrics)
   ```

3. **Cách deploy:**
   ```bash
   # Build & push image
   ./scripts/build-and-push.sh order-service v1.0.0
   
   # Deploy (rolling update)
   ./scripts/deploy.sh order-service v1.0.0
   
   # Smoke tests
   ./scripts/smoke-tests.sh
   
   # If issue → rollback
   ./scripts/rollback.sh order-service v0.9.9
   ```

4. **Monitoring & Troubleshooting:**
   - CloudWatch dashboard screenshots
   - Log examples
   - Metric graphs (CPU, memory, latency)
   - Alarm setup

5. **Chứng minh:**
   - All infrastructure deployed (terraform apply output)
   - End-to-end test (user creates order → data saved in RDS → file saved in S3)
   - Monitoring working (alarms triggered, emails received)
   - Rollback successful (no downtime)

**Tiêu chí hoàn thành tháng 1:**
- [ ] Hiểu ECR (private Docker registry)
- [ ] Biết S3 (object storage, versioning, lifecycle)
- [ ] Setup CloudWatch (logs, metrics, alarms)
- [ ] Manage secrets (Secrets Manager, Parameter Store)
- [ ] Deploy Spring Boot microservices lên AWS
- [ ] Setup monitoring & alerting
- [ ] Write deployment + rollback scripts
- [ ] Verify end-to-end flow (user → ALB → EC2 → RDS + S3)
- [ ] Có smoke tests + runbook
- [ ] Tất cả screenshots + diagrams ở README

**Sau tháng 1 → Tháng 2: Terraform + Kubernetes!** 🚀

---

## 📋 Quick Reference - AWS Services Tháng 1

| Service | Mục Đích | Output |
|---------|----------|--------|
| **ECR** | Private Docker registry | Repository URL |
| **S3** | Object storage | Bucket name |
| **CloudWatch Logs** | Centralized logging | Log group names |
| **CloudWatch Metrics** | Performance monitoring | Metric names |
| **CloudWatch Alarms** | Alert on threshold | Alarm names |
| **Secrets Manager** | Sensitive secrets | Secret names |
| **Parameter Store** | Config parameters | Parameter names |
| **IAM Roles** | Service permissions | Role ARNs |

---

## 🎯 Tổng Kết Tháng 1 (AWS Foundation)

| Tuần | Tập Trung | Output | Repo |
|-----|----------|--------|------|
| **1** | Docker | 5 containers, docker-compose.yml | springboot-docker |
| **2** | Networking | VPC, ALB, Security Groups | springboot-aws-networking |
| **3** | Compute + DB | EC2, RDS, ElastiCache | springboot-aws-compute-database |
| **4** | Storage + Deploy | ECR, S3, CloudWatch, Full stack | springboot-aws-production |

**Kết quả cuối tháng:**
- ✅ Microservices chạy trên AWS (production-ready)
- ✅ Database managed (RDS multi-AZ)
- ✅ File storage (S3)
- ✅ Monitoring (CloudWatch)
- ✅ Deployment + rollback scripts
- ✅ 4 GitHub repositories (portfolio)

**Bây giờ bạn đã ready cho Tháng 2 (Terraform + Kubernetes)!** 🚀
