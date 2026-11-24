#!/usr/bin/env bash
# ==============================================================================
# NT548 Lab 01 — Automated Infrastructure Verification Script (TC-01 -> TC-06)
# Dùng chung cho cả Terraform và CloudFormation (region: us-east-1)
#
# Cách dùng:
#   1) Tự động lấy output từ Terraform:
#      ./scripts/verify-infra.sh --from-terraform
#   2) Truyền tham số thủ công (dùng cho cả Terraform & CloudFormation):
#      ./scripts/verify-infra.sh <VPC_ID> <PUBLIC_IP> <PRIVATE_IP> [KEY_PATH]
#
# Lưu log minh chứng:
#   mkdir -p docs/evidence/test-logs
#   ./scripts/verify-infra.sh --from-terraform | tee docs/evidence/test-logs/terraform-test.txt
# ==============================================================================

set -u

AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_PATH="${HOME}/.ssh/labsuser.pem"
SSH_USER="${SSH_USER:-ec2-user}"

if [[ "${1:-}" == "--from-terraform" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TF_DIR="${SCRIPT_DIR}/../terraform"
  VPC_ID="$(terraform -chdir="${TF_DIR}" output -raw vpc_id)"
  PUBLIC_IP="$(terraform -chdir="${TF_DIR}" output -raw public_ec2_public_ip)"
  PRIVATE_IP="$(terraform -chdir="${TF_DIR}" output -raw private_ec2_private_ip)"
  KEY_PATH="${2:-${KEY_PATH}}"
elif [[ $# -ge 3 ]]; then
  VPC_ID="$1"
  PUBLIC_IP="$2"
  PRIVATE_IP="$3"
  KEY_PATH="${4:-${KEY_PATH}}"
else
  echo "Usage:"
  echo "  $0 --from-terraform [KEY_PATH]"
  echo "  $0 <VPC_ID> <PUBLIC_IP> <PRIVATE_IP> [KEY_PATH]"
  exit 1
fi

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "[ERROR] Không tìm thấy file SSH key: ${KEY_PATH}"
  exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "[PASS] $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

SSH_OPTS=(
  -i "${KEY_PATH}"
  -o StrictHostKeyChecking=accept-new
  -o BatchMode=yes
  -o ConnectTimeout=10
)

echo "=================================================================="
echo " NT548 Lab 01 — Infrastructure Verification (TC-01 -> TC-06)"
echo " Time      : $(date -Iseconds)"
echo " Region    : ${AWS_REGION}"
echo " VPC ID    : ${VPC_ID}"
echo " Public IP : ${PUBLIC_IP}"
echo " Private IP: ${PRIVATE_IP}"
echo " SSH Key   : ${KEY_PATH}"
echo "=================================================================="

# ------------------------------------------------------------------------------
# TC-01: Xác minh VPC, Subnets, IGW, Security Groups
# ------------------------------------------------------------------------------
echo ""
echo "--- [TC-01] VPC, Subnets, Internet Gateway & Security Groups ---"
aws ec2 describe-vpcs --region "${AWS_REGION}" --vpc-ids "${VPC_ID}" \
  --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,State:State}' --output table

aws ec2 describe-subnets --region "${AWS_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'Subnets[].{ID:SubnetId,CIDR:CidrBlock,PublicIP:MapPublicIpOnLaunch,AZ:AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

aws ec2 describe-internet-gateways --region "${AWS_REGION}" --filters "Name=attachment.vpc-id,Values=${VPC_ID}" \
  --query 'InternetGateways[].{ID:InternetGatewayId,State:Attachments[0].State}' --output table

aws ec2 describe-security-groups --region "${AWS_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'SecurityGroups[].{ID:GroupId,Name:GroupName,IngressCount:length(IpPermissions),EgressCount:length(IpPermissionsEgress)}' \
  --output table

SUBNET_COUNT="$(aws ec2 describe-subnets --region "${AWS_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" --query 'length(Subnets)' --output text)"
IGW_COUNT="$(aws ec2 describe-internet-gateways --region "${AWS_REGION}" --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query 'length(InternetGateways)' --output text)"
if [[ "${SUBNET_COUNT}" -ge 2 && "${IGW_COUNT}" -ge 1 ]]; then
  pass "TC-01: VPC có đủ ${SUBNET_COUNT} Subnets và ${IGW_COUNT} IGW attached"
else
  fail "TC-01: Thiếu Subnet (${SUBNET_COUNT}) hoặc IGW (${IGW_COUNT})"
fi

# ------------------------------------------------------------------------------
# TC-02: Xác minh Route Tables & NAT Gateway + Elastic IP
# ------------------------------------------------------------------------------
echo ""
echo "--- [TC-02] Route Tables & NAT Gateway + Elastic IP ---"
aws ec2 describe-route-tables --region "${AWS_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" \
  --query 'RouteTables[].{RT:RouteTableId,Name:Tags[?Key==`Name`]|[0].Value,Routes:Routes[].{Dest:DestinationCidrBlock,GW:GatewayId,NAT:NatGatewayId}}' \
  --output json

aws ec2 describe-nat-gateways --region "${AWS_REGION}" --filter "Name=vpc-id,Values=${VPC_ID}" "Name=state,Values=available" \
  --query 'NatGateways[].{ID:NatGatewayId,State:State,Subnet:SubnetId,EIP:NatGatewayAddresses[0].PublicIp}' \
  --output table

NAT_COUNT="$(aws ec2 describe-nat-gateways --region "${AWS_REGION}" --filter "Name=vpc-id,Values=${VPC_ID}" "Name=state,Values=available" --query 'length(NatGateways)' --output text)"
if [[ "${NAT_COUNT}" -ge 1 ]]; then
  pass "TC-02: NAT Gateway ở trạng thái available kèm Elastic IP"
else
  fail "TC-02: Không tìm thấy NAT Gateway ở trạng thái available"
fi

# ------------------------------------------------------------------------------
# TC-03: SSH từ máy cá nhân -> Public EC2 (Bastion)
# ------------------------------------------------------------------------------
echo ""
echo "--- [TC-03] SSH từ máy cá nhân -> Public EC2 (${PUBLIC_IP}) ---"
if PUB_OUT="$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${PUBLIC_IP}" 'hostname -I' 2>&1)"; then
  echo "Public EC2 hostname -I: ${PUB_OUT}"
  pass "TC-03: SSH vào Public EC2 thành công"
else
  echo "Output: ${PUB_OUT}"
  fail "TC-03: Không thể SSH vào Public EC2"
fi

# ------------------------------------------------------------------------------
# TC-04: Xác nhận KHÔNG thể SSH trực tiếp từ Internet -> Private EC2
# ------------------------------------------------------------------------------
echo ""
echo "--- [TC-04] Chặn SSH trực tiếp từ Internet -> Private EC2 (${PRIVATE_IP}) ---"
aws ec2 describe-instances --region "${AWS_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}' \
  --output table

if ssh -i "${KEY_PATH}" -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 "${SSH_USER}@${PRIVATE_IP}" 'hostname -I' >/dev/null 2>&1; then
  fail "TC-04: CẢNH BÁO — Có thể SSH trực tiếp vào Private EC2!"
else
  pass "TC-04: SSH trực tiếp vào Private EC2 bị chặn / timeout đúng kỳ vọng"
fi

# ------------------------------------------------------------------------------
# TC-05: SSH Bastion ProxyJump (-J) -> Private EC2 (không copy .pem lên Bastion)
# ------------------------------------------------------------------------------
echo ""
echo "--- [TC-05] SSH ProxyJump (-J) qua Bastion -> Private EC2 (${PRIVATE_IP}) ---"
PROXY_CMD="ssh -i ${KEY_PATH} -o StrictHostKeyChecking=accept-new -o BatchMode=yes -W %h:%p ${SSH_USER}@${PUBLIC_IP}"
if PRIV_OUT="$(ssh "${SSH_OPTS[@]}" -o "ProxyCommand=${PROXY_CMD}" "${SSH_USER}@${PRIVATE_IP}" 'hostname -I' 2>&1)"; then
  echo "Private EC2 hostname -I: ${PRIV_OUT}"
  pass "TC-05: SSH ProxyJump vào Private EC2 thành công (không copy .pem lên Bastion)"
else
  echo "Output: ${PRIV_OUT}"
  fail "TC-05: SSH ProxyJump vào Private EC2 thất bại"
fi

# ------------------------------------------------------------------------------
# TC-06: Private EC2 truy cập Internet chiều đi (Outbound) qua NAT Gateway
# ------------------------------------------------------------------------------
echo ""
echo "--- [TC-06] Private EC2 Outbound Internet qua NAT Gateway (curl + ping) ---"
if NAT_OUT="$(ssh "${SSH_OPTS[@]}" -o "ProxyCommand=${PROXY_CMD}" "${SSH_USER}@${PRIVATE_IP}" 'curl -IsS --max-time 10 https://google.com | head -n 1 && ping -c 4 8.8.8.8' 2>&1)"; then
  echo "${NAT_OUT}"
  pass "TC-06: Private EC2 truy cập HTTPS (google.com) và ICMP (8.8.8.8) qua NAT Gateway thành công"
else
  echo "${NAT_OUT}"
  fail "TC-06: Private EC2 không thể ra Internet qua NAT Gateway"
fi

# ------------------------------------------------------------------------------
# Tổng kết
# ------------------------------------------------------------------------------
echo ""
echo "=================================================================="
echo " SUMMARY: PASS = ${PASS_COUNT} | FAIL = ${FAIL_COUNT}"
echo "=================================================================="
[[ "${FAIL_COUNT}" -eq 0 ]]
