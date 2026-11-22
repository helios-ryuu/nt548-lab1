1. Chuẩn bị môi trường và các công cụ cần thiết:
- Cài đặt AWS CLI trên máy tính cá nhân.
- Cài đặt Terraform CLI trên máy tính cá nhân.
- Cài đặt Python và pip trên máy tính cá nhân (nếu đã có thì không cần cài)
- Thiết lập CloudFormation Linter trong dự án trên máy tính cá nhân bằng Python virtual environment:
    - Tạo một virtual environment: `python3 -m venv .venv`
    - Kích hoạt virtual environment:
        - Trên Windows: `.venv\Scripts\activate`
        - Trên macOS/Linux: `source .venv/bin/activate`
    - Cài đặt CloudFormation Linter: `pip install cfn-lint`
    - Kiểm tra cài đặt: `cfn-lint --version`
- Tạo `~/.aws/config` và `~/.aws/credentials` để cấu hình AWS CLI với thông tin tài khoản AWS của bạn:
    - `~/.aws/config`:
        ```
        [default]
        region = us-east-1
        output = json
        ```
    - `~/.aws/credentials` (Lấy thông tin từ AWS Academy Learner Lab -> AWS Details sau khi Start Lab):
        ```
        [default]
        aws_access_key_id = YOUR_ACCESS_KEY_ID
        aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
        aws_session_token = YOUR_SESSION_TOKEN
        ```
    - Khóa quyền đọc file: `chmod 600 ~/.aws/credentials`
    - Xác minh kết nối Learner Lab:
        - `aws --version`
        - `aws sts get-caller-identity`
> `aws sts get-caller-identity` sẽ trả về thông tin tài khoản AWS của bạn, bao gồm `Account`, `UserId`, và `Arn`. Nếu lệnh này thành công, bạn đã kết nối thành công với Learner Lab.
- Tải file `labsuser.pem` (tên Key Pair có sẵn trên AWS EC2 là **`vockey`**) từ AWS Academy Learner Lab -> AWS Details -> SSH Key -> Download PEM. Lưu file này vào thư mục ~/.ssh/ trên máy tính cá nhân và đặt quyền đọc file: `chmod 400 ~/.ssh/labsuser.pem`.
- Xác nhận Key Pair vockey đã tồn tại trên AWS EC2 (us-east-1): `aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --output text`