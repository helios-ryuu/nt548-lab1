# ARCHITECTURE — Kiến Trúc Hạ Tầng AWS (NT548 Lab 01)

Tài liệu này mô tả chi tiết kiến trúc mạng và máy chủ AWS được triển khai đồng nhất bằng **Terraform (Modules)** và **AWS CloudFormation (Nested Stacks)** trên môi trường **AWS Academy Learner Lab (`us-east-1`)**, kèm sơ đồ ASCII tỉ lệ **16:9** làm bản thiết kế chuẩn để vẽ lại bằng **Draw.io** (kèm AWS Architecture Icons).

---

## 1. Sơ Đồ Kiến Trúc Tổng Thể (ASCII — Tỉ Lệ 16:9)

> **Quy ước luồng:** `[1]` SSH vào Bastion · `[2]` SSH ProxyJump vào Private EC2 · `[3]` Outbound Internet qua NAT GW · `[X]` Chặn truy cập trực tiếp từ Internet.

```text
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                       NT548 LAB 01 — AWS VPC NETWORK ARCHITECTURE (2:1 WIDE — 180x45)                                                            |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                                                                                                                                  |
|                                             +---------------------------------------------------------------------------------------------------------------------------------+  |
|  +-----------------------+                  |  [ICON: AWS Cloud]  Region: us-east-1 (N. Virginia)  |  AWS Academy Learner Lab  |  No IAM Created                              |  |
|  | [ICON: Client / PC]   |                  |                                                                                                                                 |  |
|  | May Ca Nhan (Admin)   |                  |  +---------------------------------------------------------------------------------------------------------------------------+  |  |
|  | IP  : <MY_IP>/32      |                  |  |  [ICON: VPC]  nt548-lab1-vpc (10.0.0.0/16)  |  DNS Support: ON  |  DNS Hostnames: ON  |  Default SG: RESTRICTED (0 rules) |  |  |
|  | Key : labsuser.pem    |                  |  |                                                                                                                           |  |  |
|  | SSH : ProxyJump (-J)  |                  |  |                                    +-----------------------------------------------------------------------------------+  |  |  |
|  +-----------------------+                  |  |                                    |  Availability Zone: us-east-1a                                                    |  |  |  |
|              |                              |  |                                    |                                                                                   |  |  |  |
|              |                              |  |                                    |  +----------------------------------+              +---------------------------+  |  |  |  |
|    [1] SSH (TCP 22)                         |  |                                    |  | [ICON: Public Subnet] 10.0.1.0/24|              | [ICON: Private] 10.0.2.0/24  |  |  |  |
|              |                              |  |                                    |  | nt548-lab1-public-subnet (PubIP) |              | private-subnet (No PubIP) |  |  |  |  |
|              |                              |  |                                    |  | +------------------------------+ |              | +-----------------------+ |  |  |  |  |
|              v                              |  |                                    |  | | [ICON: RT] public-rt         | |              | | [ICON: RT] private-rt | |  |  |  |  |
|  +-----------------------+                  |  |  +------------------+              |  | | 10.0.0.0/16->loc | 0/0->IGW  | |              | | 0.0.0.0/0 -> NAT GW   | |  |  |  |  |
|  |  [ICON: Internet]     |--- [1] SSH TCP 22 ---->| [ICON: IGW]      |              |  | +------------------------------+ |              | +-----------------------+ |  |  |  |  |
|  |       INTERNET        |                  |  |  | nt548-lab1-igw   |              |  |                                  |              |                           |  |  |  |  |
|  | google.com / 8.8.8.8  |                  |  |  | Internet Gateway |              |  | +------------------------------+ |              |                           |  |  |  |  |
|  |  (Public Network)     |                  |  |  | (Attached to VPC)|              |  | | [ICON: NAT GW] nat-gw        |<-- [3] HTTP/HTTPS/ICMP ------+             |  |  |  |  |
|  |                       |<-- [3] Outbound -------|                  |<- [3] NAT Out ----| + [ICON: EIP]  nat-eip       | |              |             |             |  |  |  |  |
|  +-----------------------+                  |  |  +------------------+              |  | +------------------------------+ |              |             |             |  |  |  |  |
|              :                              |  |            |                       |  |                                  |              |             |             |  |  |  |  |
|              :                              |  |            |                       |  | +------------------------------+ |              | +-----------------------+ |  |  |  |  |
|              :                              |  |            |                       |  | | SG: public-ec2-sg            | |              | | SG: private-ec2-sg    | |  |  |  |  |
|              :                              |  |            |                       |  | | In: TCP 22 (<MY_IP>/32)      | |              | | In: TCP 22 (Pub SG)   | |  |  |  |  |
|              :                              |  |            |                       |  | | +--------------------------+ | |              | | +-------------------+ | |  |  |  |  |
|              :                              |  |            |                       |  | | | [ICON: EC2] Public EC2   | | |              | | | [ICON: EC2] Private | |  |  |  |  |
|              :                              |  |            |                       |  | | | (Bastion) | t3.micro     | | |              | | | AL2023 | t3.micro | | |  |  |  |  |
|              :                              |  |            +------ [1] SSH TCP 22 ------->| AL2023 | Pub+Priv IP     |---- [2] ProxyJump -->| Private IP ONLY   | | |  |  |  |  |
|              :                              |  |                                    |  | | | vockey | IMDSv2 | Enc    | | |              | | | vockey|IMDSv2|Enc | | |  |  |  |  |
|              :                              |  |                                    |  | | +--------------------------+ | |              | | +-------------------+ | |  |  |  |  |
|              :                              |  |                                    |  | +------------------------------+ |              | +-----------------------+ |  |  |  |  |
|              :                              |  |                                    |  +----------------------------------+              +-------------X-------------+  |  |  |  |
|              :                              |  |                                    +------------------------------------------------------------------:----------------+  |  |  |
|              :                              |  +-------------------------------------------------------------------------------------------------------:-------------------+  |  |
|              :                              +----------------------------------------------------------------------------------------------------------:----------------------+  |
|              :                                                                                                                                         :                         |
|              :                                                                                                                                         :                         |
|              +.............................. [X] Direct SSH from Internet -> Private EC2 : BLOCKED (No Public IP & Private SG) ........................+                         |
|                                                                                                                                                                                  |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

---

## 2. Các Thành Phần Hạ Tầng Và Thứ Tự Khởi Tạo Trong Terraform

Toàn bộ hạ tầng được đặt tại Region **`us-east-1`** (AZ **`us-east-1a`**), không tạo mới bất kỳ tài nguyên IAM nào để tương thích tuyệt đối với **AWS Academy Learner Lab**.

### 2.1. Nhóm Mạng — Module `vpc` (11 tài nguyên)

| STT | Tài Nguyên AWS | Tên / Tag (`Name`) | Cấu Hình Chi Tiết | Vai Trò Trong Kiến Trúc |
| :-: | :--- | :--- | :--- | :--- |
| 1 | **VPC** | `nt548-lab1-vpc` | CIDR `10.0.0.0/16`, bật `DNS support` & `DNS hostnames` | Mạng riêng ảo cô lập toàn bộ hạ tầng bài lab |
| 2 | **Default Security Group** | `nt548-lab1-default-sg-restricted` | Xóa sạch toàn bộ rule `ingress` và `egress` | Giảm bề mặt tấn công; đạt chuẩn Checkov `CKV2_AWS_12` cho Lab 02 |
| 3 | **Internet Gateway (IGW)** | `nt548-lab1-igw` | Gắn vào `nt548-lab1-vpc` | Cổng giao tiếp 2 chiều giữa VPC và Internet |
| 4 | **Public Subnet** | `nt548-lab1-public-subnet` | `10.0.1.0/24` (`us-east-1a`), `MapPublicIpOnLaunch = true` | Chứa Public EC2 (Bastion) và NAT Gateway |
| 5 | **Private Subnet** | `nt548-lab1-private-subnet` | `10.0.2.0/24` (`us-east-1a`), `MapPublicIpOnLaunch = false` | Chứa Private EC2, cách ly hoàn toàn khỏi Internet chiều vào |
| 6 | **Elastic IP (EIP)** | `nt548-lab1-nat-eip` | `domain = "vpc"` | IP tĩnh công cộng cấp cho NAT Gateway |
| 7 | **NAT Gateway** | `nt548-lab1-nat-gw` | Đặt trong `Public Subnet`, gắn `nt548-lab1-nat-eip` | Cho phép Private Subnet ra Internet (outbound) nhưng chặn chiều vào |
| 8 | **Public Route Table** | `nt548-lab1-public-rt` | `10.0.0.0/16 → local`; `0.0.0.0/0 → IGW` | Định tuyến lưu lượng Internet của Public Subnet qua IGW |
| 9 | **Private Route Table** | `nt548-lab1-private-rt` | `10.0.0.0/16 → local`; `0.0.0.0/0 → NAT GW` | Định tuyến lưu lượng outbound của Private Subnet qua NAT Gateway |
| 10 | **Route Table Associations** | *(2 liên kết)* | Gắn `public-rt ↔ public-subnet`, `private-rt ↔ private-subnet` | Áp dụng bảng định tuyến tương ứng cho từng Subnet |

### 2.2. Nhóm Bảo Mật — Module `security_group` (2 tài nguyên)

| STT | Security Group | Inbound Rules (Ingress) | Outbound Rules (Egress) | Nguyên Tắc Bảo Mật |
| :-: | :--- | :--- | :--- | :--- |
| 11 | **`nt548-lab1-public-ec2-sg`** | `TCP 22` **chỉ từ `<MY_IP>/32`** | `All traffic (-1)` → `0.0.0.0/0` | Không bao giờ mở SSH `0.0.0.0/0`; chỉ đúng IP máy quản trị |
| 12 | **`nt548-lab1-private-ec2-sg`** | `TCP 22` **chỉ từ `nt548-lab1-public-ec2-sg`** | `All traffic (-1)` → `0.0.0.0/0` | Security Group chaining — chỉ nhận SSH từ Bastion, cho phép outbound `curl`/`ping` qua NAT GW |

### 2.3. Nhóm Máy Chủ — Module `ec2` (2 tài nguyên)

| STT | Tài Nguyên | Tên (`Name`) | Thông Số Chính | Bảo Mật Tích Hợp |
| :-: | :--- | :--- | :--- | :--- |
| 13 | **Public EC2 (Bastion)** | `nt548-lab1-public-ec2` | Amazon Linux 2023 (x86_64), `t3.micro`, Key Pair `vockey`, có Public IP | IMDSv2 (`http_tokens = required`), EBS `gp3` 8GB mã hóa (`encrypted = true`) |
| 14 | **Private EC2 (Internal)** | `nt548-lab1-private-ec2` | Amazon Linux 2023 (x86_64), `t3.micro`, Key Pair `vockey`, **không có Public IP** | IMDSv2 (`http_tokens = required`), EBS `gp3` 8GB mã hóa (`encrypted = true`) |

### 2.4. Thứ Tự Khởi Tạo Thực Tế Trong Terraform (`terraform apply` — DAG)

Terraform tự động xây dựng **đồ thị phụ thuộc (DAG)** và tạo song song các tài nguyên độc lập theo 5 tầng. Kết quả thực nghiệm thực tế (`Apply complete! Resources: 15 added, 0 changed, 0 destroyed` — tổng thời gian **2m32s**):

| Tầng | Tài Nguyên Khởi Tạo Song Song | Thời Gian Thực Tế | Phụ Thuộc (Chờ Xong Trước) |
| :-: | :--- | :---: | :--- |
| **0** | `data.aws_ami.amazon_linux_2023` | *(lúc `plan`)* | *(Tra cứu AMI mới nhất trên `us-east-1`)* |
| **1** | `aws_eip.nat` · `aws_vpc.this` | `4s` · `15s` | Không phụ thuộc |
| **2** | `aws_subnet.private` · `aws_internet_gateway.this` · `aws_default_security_group.default` · `aws_security_group.public_ec2` · `aws_subnet.public` | `2s` · `2s` · `4s` · `6s` · `13s` | `aws_vpc.this` |
| **3** | `aws_route_table.public` · `aws_security_group.private_ec2` · `aws_instance.private` · `aws_instance.public` · `aws_nat_gateway.this` | `3s` · `5s` · `16s` · `16s` · **`1m59s`** | Tầng 2 (`IGW`, `EIP`, `Subnets`, `SGs`, `AMI`) |
| **4** | `aws_route_table_association.public` · `aws_route_table.private` | `1s` · `2s` | `Public RT` + `Public Subnet` · `NAT Gateway` |
| **5** | `aws_route_table_association.private` | `2s` | `Private Subnet` + `Private RT` |

> **Nhận xét thực tế:** `aws_nat_gateway.this` là nút thắt thời gian lớn nhất (**`1m59s`** / `2m32s`), trong khi cả 2 máy chủ EC2 (`aws_instance.private` và `aws_instance.public`, mỗi máy **`16s`**) được Terraform tạo song song ngay khi Subnet và Security Group tương ứng sẵn sàng mà không cần chờ NAT Gateway.  
> **Khi chạy `terraform destroy`:** Terraform tự động hủy toàn bộ 15 tài nguyên theo **thứ tự đảo ngược 100%** (từ Tầng 5 về Tầng 1: xóa EC2 và Route Table Associations → Private RT và NAT Gateway → giải phóng EIP, Subnets, IGW, Security Groups → xóa VPC cuối cùng).

---

## 3. Phân Tích 4 Luồng Lưu Lượng Chính (Traffic Flows)

1. **`[1]` Quản trị SSH vào Public EC2 (Bastion):**
   - `Máy cá nhân (<MY_IP>/32)` → `Internet` → `IGW` → `Public Route Table` → `Public EC2 SG (cho phép TCP 22 từ /32)` → `Public EC2`.
2. **`[X]` Chặn truy cập trực tiếp từ Internet vào Private EC2:**
   - Private EC2 **không có Public IP**, nằm trong Private Subnet không có route tới IGW, và `Private EC2 SG` chỉ nhận kết nối từ `Public EC2 SG`. Mọi kết nối trực tiếp từ Internet đều bị chặn (`Connection timed out`).
3. **`[2]` SSH nhảy (Bastion `ProxyJump`) vào Private EC2:**
   - `Máy cá nhân` dùng cờ `-J` (`ssh -i ~/.ssh/labsuser.pem -J ec2-user@<PUBLIC_IP> ec2-user@<PRIVATE_IP>`) đi qua `Public EC2` sang `Private EC2` qua mạng nội bộ VPC (`10.0.0.0/16 -> local`).
   - **Lợi ích bảo mật:** File khóa riêng `labsuser.pem` nằm hoàn toàn trên máy cá nhân, **tuyệt đối không copy lên Bastion Host**.
4. **`[3]` Private EC2 truy cập Internet chiều đi (Outbound) qua NAT Gateway:**
   - `Private EC2` → `Private Route Table (0.0.0.0/0 -> NAT GW)` → `NAT Gateway + EIP (trong Public Subnet)` → `Public Route Table (0.0.0.0/0 -> IGW)` → `IGW` → `Internet` (ví dụ `curl -I https://google.com`, `ping -c 4 8.8.8.8`, `dnf update`).

---

## 4. Hướng Dẫn Vẽ Lại Bằng Draw.io (Dành Cho TV4 — Task 1.4.1)

- **Kích thước trang (Canvas):** Chọn **16:9** (`1920 × 1080 px` hoặc `1600 × 900 px`, khổ ngang Landscape) để xuất PNG sắc nét đưa vào Báo cáo Word.
- **Thư viện Icon trong Draw.io:** Bấm **More Shapes...** → bật **AWS 2024** (hoặc **AWS 2025**).
- **Bảng ánh xạ Icon & Màu khung chuẩn AWS:**

| Thành Phần Trên Sơ Đồ | Tên Shape / Icon Trong Draw.io (AWS) | Màu Khung Chuẩn |
| :--- | :--- | :--- |
| Khung ngoài cùng | `AWS Cloud` | Viền đen/xám đậm |
| Khung Region | `Region` (`us-east-1`) | Viền xanh dương nét đứt |
| Khung VPC | `VPC` (`10.0.0.0/16`) | Viền xanh lá đậm |
| Khung AZ | `Availability Zone` (`us-east-1a`) | Viền xanh dương nét đứt |
| Khung Public Subnet | `Public subnet` (`10.0.1.0/24`) | Nền xanh lá nhạt |
| Khung Private Subnet | `Private subnet` (`10.0.2.0/24`) | Nền xanh dương nhạt |
| Khung Security Group | Hình chữ nhật nét đứt | Viền đỏ đậm |
| Tài nguyên mạng | `Internet gateway`, `NAT gateway`, `Elastic IP`, `Route table` | Icon màu tím (Networking) |
| Máy chủ | `EC2` (hoặc `EC2 Instance`) | Icon màu cam (Compute) |
| Bên ngoài | `Client` / `User` + `Internet` | Icon màu xám/đen |
