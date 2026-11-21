# RUNBOOK — NT548 Lab 01 (Sổ Tay Vận Hành, Kiểm Thử & Phối Hợp Nhóm)

Tài liệu này là quy trình thao tác chuẩn (SOP) dành cho **Tech Lead** khi triển khai/hủy hạ tầng và cho **3 thành viên hỗ trợ** khi chạy test, chụp ảnh minh chứng và đẩy tài liệu lên GitHub.

---

## SOP 1 — Khởi Động Phiên AWS Academy Learner Lab (Mỗi Phiên 4 Giờ)

### 1.1. Kiểm tra lần đầu (chỉ làm 1 lần ngày đầu tiên)
1. Vào khóa **AWS Academy Learner Lab [189923]** trên Canvas → mục **Modules**.
2. Hoàn thành **Module Knowledge Check** (yêu cầu đạt `>= 70/100`) nếu hệ thống yêu cầu trước khi mở lab.
3. Mở mục **AWS Academy Learner Lab Resources** để tải/đọc danh sách dịch vụ được phép dùng trong sandbox.

### 1.2. Nạp Credentials mỗi khi bắt đầu phiên làm việc
1. Mở **Launch AWS Academy Learner Lab** → bấm **Start Lab** → đợi chấm tròn cạnh chữ `AWS` chuyển sang **xanh lá**.
2. Bấm **AWS Details** → bấm **Show** tại mục **AWS CLI** → sao chép toàn bộ khối `[default]`.
3. Dán vào `~/.aws/credentials`:
   ```ini
   [default]
   aws_access_key_id=ASIA...
   aws_secret_access_key=...
   aws_session_token=...
   ```
4. Đảm bảo `~/.aws/config` khóa cứng region **`us-east-1`**:
   ```ini
   [default]
   region = us-east-1
   output = json
   ```
5. Xác minh phiên làm việc hợp lệ:
   ```bash
   aws sts get-caller-identity
   ```
   > **Lưu ý:** Nếu đang làm việc gần hết 4 tiếng, bấm lại nút **Start Lab** để gia hạn timer và cập nhật lại `aws_session_token` mới.

### 1.3. Chuẩn bị SSH Key Pair & lấy IP cá nhân (`/32`)
```bash
# Lấy Public IP hiện tại của máy cá nhân
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "My IP CIDR: ${MY_IP}/32"

# Tạo SSH Key Pair mới trên AWS (hoặc dùng Key Pair có sẵn vockey của Learner Lab)
aws ec2 create-key-pair \
  --key-name nt548-lab1-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/nt548-lab1-key.pem
chmod 400 ~/.ssh/nt548-lab1-key.pem
```
> **Cấm tuyệt đối:** Không lưu file `.pem` vào trong thư mục repo Git. Luôn giữ `.pem` ở `~/.ssh/`.

---

## SOP 2 — Triển Khai & Hủy Hạ Tầng Bằng Terraform

### 2.1. Cấu hình biến và triển khai
```bash
cd /home/helios/main/projects/nt548-lab1/terraform

# Tạo file biến local (file này đã được .gitignore chặn)
cp terraform.tfvars.example terraform.tfvars
# Chỉnh sửa my_ip_cidr = "<MY_IP>/32" và key_name = "nt548-lab1-key"

# Khởi tạo, kiểm tra format/cú pháp, xem kế hoạch và áp dụng
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=lab1.tfplan
terraform apply lab1.tfplan

# Xem danh sách output (VPC ID, Subnet IDs, Public IP, Private IP...)
terraform output
```

### 2.2. Điểm kiểm tra bắt buộc trong code Terraform
- Toàn bộ tài nguyên chia vào 3 module: `modules/vpc`, `modules/security_group`, `modules/ec2`.
- Default Security Group quản lý bằng `aws_default_security_group` và **đóng toàn bộ ingress/egress** (tương thích sẵn với Checkov `CKV2_AWS_12` ở Lab 02).
- NAT Gateway đặt trong **Public Subnet** và gắn **Elastic IP (`aws_eip`)**.
- **Không** định nghĩa bất kỳ resource `aws_iam_*` nào (Learner Lab chặn tạo IAM). Nếu EC2 cần profile, dùng tên có sẵn `LabInstanceProfile`.

### 2.3. Hủy toàn bộ hạ tầng ngay sau khi test xong
```bash
cd /home/helios/main/projects/nt548-lab1/terraform
terraform destroy -auto-approve
rm -f lab1.tfplan
```

---

## SOP 3 — Triển Khai & Hủy Hạ Tầng Bằng CloudFormation (Nested Stacks)

### 3.1. Bootstrap S3 Bucket & Upload Nested Templates
```bash
export AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CFN_BUCKET="nt548-lab1-cfn-${ACCOUNT_ID}-${AWS_REGION}"

# Tạo bucket (bỏ qua nếu đã tồn tại)
aws s3 mb "s3://${CFN_BUCKET}" --region "${AWS_REGION}" || true

# Kiểm tra cú pháp từng file template trước khi upload
cfn-lint cloudformation/main.yaml cloudformation/templates/*.yaml || true

# Upload các nested template lên S3
aws s3 sync cloudformation/templates/ "s3://${CFN_BUCKET}/templates/" --delete
```

### 3.2. Triển khai Root Stack
```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)

aws cloudformation deploy \
  --stack-name nt548-lab1-stack \
  --template-file cloudformation/main.yaml \
  --parameter-overrides \
    TemplateBucketName="${CFN_BUCKET}" \
    TemplatePrefix="templates" \
    MyIpCidr="${MY_IP}/32" \
    KeyName="nt548-lab1-key" \
  --region "${AWS_REGION}"

# Xem Outputs của Stack (Public IP, Private IP, VPC ID...)
aws cloudformation describe-stacks \
  --stack-name nt548-lab1-stack \
  --query 'Stacks[0].Outputs' \
  --output table
```

> **Lưu ý về Default SG trong CloudFormation:** AWS không hỗ trợ tạo resource mới thay thế Default SG mặc định của VPC. Stack xuất `!GetAtt VPC.DefaultSecurityGroup` để chứng minh sự tồn tại và tạo bổ sung baseline SG (hoặc tài liệu hóa rõ ràng trong báo cáo).

### 3.3. Xóa Stack ngay sau khi kiểm thử xong
```bash
aws cloudformation delete-stack --stack-name nt548-lab1-stack --region us-east-1
aws cloudformation wait stack-delete-complete --stack-name nt548-lab1-stack --region us-east-1
```

---

## SOP 4 — Bộ Lệnh Kiểm Thử Từng Dịch Vụ (Test Cases)

Thay `<VPC_ID>`, `<PUBLIC_IP>`, `<PRIVATE_IP>` bằng giá trị từ `terraform output` hoặc `cloudformation describe-stacks`.

### 4.1. TC-01 & TC-02 — Kiểm chứng VPC, Subnets, IGW, Route Tables, NAT GW, EIP, SGs
```bash
# 1. VPC & Subnets
aws ec2 describe-vpcs --vpc-ids <VPC_ID> --output table
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'Subnets[].{ID:SubnetId,CIDR:CidrBlock,PublicIP:MapPublicIpOnLaunch,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

# 2. Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<VPC_ID>" --output table

# 3. Route Tables (kiểm tra 0.0.0.0/0 -> igw-... và 0.0.0.0/0 -> nat-...)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'RouteTables[].{RT:RouteTableId,Routes:Routes[].{Dest:DestinationCidrBlock,GW:GatewayId,NAT:NatGatewayId}}'

# 4. NAT Gateway (trạng thái phải là available và có EIP)
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<VPC_ID>" \
  --query 'NatGateways[].{ID:NatGatewayId,State:State,Subnet:SubnetId,EIP:NatGatewayAddresses[0].PublicIp}' \
  --output table

# 5. Security Groups & Rules
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'SecurityGroups[].{ID:GroupId,Name:GroupName,Ingress:IpPermissions}'
```

### 4.2. TC-03 — SSH từ máy cá nhân vào Public EC2
```bash
ssh -i ~/.ssh/nt548-lab1-key.pem ec2-user@<PUBLIC_IP>
# Kỳ vọng: Đăng nhập thành công; chạy `hostname -I` thấy Private IP thuộc Public Subnet.
exit
```

### 4.3. TC-04 — Xác nhận KHÔNG thể SSH trực tiếp vào Private EC2 từ Internet
```bash
# Kiểm tra Private EC2 không có Public IP
aws ec2 describe-instances --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}' \
  --output table

# Thử SSH trực tiếp vào Private IP (sẽ timeout sau 5 giây)
ssh -i ~/.ssh/nt548-lab1-key.pem -o ConnectTimeout=5 ec2-user@<PRIVATE_IP>
# Kỳ vọng: Connection timed out (chứng minh Private EC2 bị cách ly khỏi Internet).
```

### 4.4. TC-05 & TC-06 — SSH Bastion (`ProxyJump`) sang Private EC2 & Test Outbound qua NAT GW
> **An toàn bảo mật:** Dùng `-J` (`ProxyJump`) để giữ private key `.pem` hoàn toàn trên máy cá nhân, **tuyệt đối không `scp` file `.pem` lên Public EC2**.

```bash
ssh -i ~/.ssh/nt548-lab1-key.pem \
    -J ec2-user@<PUBLIC_IP> \
    ec2-user@<PRIVATE_IP>
```
Sau khi vào được shell của **Private EC2**, chạy 3 lệnh sau và chụp màn hình:
```bash
# Xác nhận đang ở Private Subnet
hostname -I

# Kiểm tra kết nối HTTP/HTTPS + DNS qua NAT Gateway
curl -I https://google.com

# Kiểm tra kết nối ICMP qua NAT Gateway (Private SG cần cho phép outbound)
ping -c 4 8.8.8.8
```

---

## SOP 5 — Checklist Dọn Sạch Tài Nguyên Cuối Phiên (Chống Cháy 50 USD)

Chạy toàn bộ khối lệnh dưới đây **trước khi đóng phiên Learner Lab**. Tất cả kết quả phải rỗng (`[]`) hoặc trạng thái `terminated`/`deleted`:

```bash
echo "=== 1. EC2 còn đang chạy ==="
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}' \
  --output table

echo "=== 2. NAT Gateways còn hoạt động (NGỐN TIỀN NGẦM!) ==="
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=pending,available" \
  --query 'NatGateways[].{ID:NatGatewayId,State:State}' \
  --output table

echo "=== 3. Elastic IPs chưa giải phóng (TÍNH PHÍ $0.005/h!) ==="
aws ec2 describe-addresses \
  --query 'Addresses[].{AllocId:AllocationId,IP:PublicIp,Assoc:AssociationId}' \
  --output table

echo "=== 4. CloudFormation Stacks đang tồn tại ==="
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE CREATE_IN_PROGRESS DELETE_FAILED \
  --query 'StackSummaries[].{Name:StackName,Status:StackStatus}' \
  --output table
```

> Nếu phát hiện EIP mồ côi (`Assoc: None`), giải phóng ngay bằng:
> ```bash
> aws ec2 release-address --allocation-id <eipalloc-xxxx>
> ```

---

## SOP 6 — Hướng Dẫn Cho 3 Thành Viên Hỗ Trợ (Minh Chứng & Git Tối Giản)

### 6.1. Quy ước đặt tên ảnh minh chứng (`docs/evidence/`)
Đặt tên rõ ràng, không dấu tiếng Việt, không khoảng trắng để TV4 ghép báo cáo nhanh:
- Terraform: `tf-01-apply.png`, `tf-02-vpc-subnets.png`, `tf-03-route-nat.png`, `tf-04-sg-rules.png`, `tf-05-ec2-list.png`, `tf-06-ssh-public.png`, `tf-07-ssh-private-fail.png`, `tf-08-ssh-proxyjump-nat.png`, `tf-09-destroy.png`
- CloudFormation: `cfn-01-s3-templates.png`, `cfn-02-nested-stacks.png`, `cfn-03-outputs.png`, `cfn-04-ssh-proxyjump-nat.png`, `cfn-05-delete-stack.png`

### 6.2. Phân vùng thư mục không xung đột
- **TV1 — Ngô Tiến Sỹ (`23521367`, Tech Lead):** `terraform/`, `cloudformation/`, `scripts/`
- **TV2 — Trần Hồng Phúc (`23521222`, App Dev & Test Support):** `docs/evidence/test-logs/`
- **TV3 — Điền Quốc Huy (`23520600`, QA & Evidence):** `docs/evidence/`
- **TV4 — Đặng Thế Long (`22520804`, Diagrams, Report & Docs):** `docs/diagrams/`, `docs/report/`, cập nhật tiến độ `WBS.md`

### 6.3. Cheatsheet Git 5 Lệnh Tối Giản (Dành cho Phúc, Huy, Long)
Mỗi thành viên chỉ làm việc trên thư mục của mình và chạy đúng 5 bước sau mỗi lần cập nhật:
```bash
# 1. Lấy code mới nhất trước khi làm (tránh conflict)
git pull --rebase origin main

# 2. Kiểm tra các file mình vừa thêm/sửa
git status

# 3. Đưa file vào staging (CHỈ add thư mục của mình)
git add docs/evidence/

# 4. Tạo commit rõ ràng
git commit -m "docs(evidence): add terraform test screenshots"

# 5. Đẩy lên GitHub
git push origin main
```
> **Mẹo chống lỗi:** Nếu `git push` báo từ chối do người khác vừa push trước, chỉ cần chạy lại `git pull --rebase origin main` rồi `git push origin main`. Không sửa các file trong `terraform/` hoặc `cloudformation/` nếu chưa trao đổi với Tech Lead.

---

## SOP 7 — Troubleshooting Nhanh

| Lỗi Gặp Phải | Nguyên Nhân | Cách Khắc Phục |
| :--- | :--- | :--- |
| `ExpiredToken` / `InvalidClientTokenId` | Phiên 4h của Learner Lab đã hết hạn | Mở Learner Lab → **Start Lab** → copy lại 3 khóa mới vào `~/.aws/credentials` |
| `AccessDenied` / `UnauthorizedOperation` | Deploy nhầm Region khác `us-east-1` hoặc tạo tài nguyên IAM | Kiểm tra `aws configure get region` phải là `us-east-1`; xóa mọi block tạo IAM role/user |
| SSH vào Public EC2 bị `Connection timed out` | IP Wi-Fi/mạng nhà vừa thay đổi khác với `my_ip_cidr` trong SG | Chạy lại `curl -s https://checkip.amazonaws.com`, cập nhật `my_ip_cidr` và `apply`/update stack |
| `DependencyViolation` khi `destroy` hoặc xóa Stack | NAT Gateway đang xóa chậm hoặc còn ENI/SG phụ thuộc | Đợi 1–2 phút cho NAT Gateway chuyển `deleted` rồi chạy lại `terraform destroy` hoặc `delete-stack` |
| Private EC2 `curl` được nhưng `ping 8.8.8.8` fail | Private SG chỉ mở egress TCP mà chặn ICMP | Mở egress `All traffic` (`-1`) cho Private EC2 SG (hoặc mở riêng ICMP outbound) |
