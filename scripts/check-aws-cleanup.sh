#!/usr/bin/env bash
# ==============================================================================
# NT548 Lab 01 — AWS Cleanup Verification Script (TC-07 / SOP 5)
# Kiểm tra sạch 0 EC2 / 0 NAT GW / 0 EIP / 0 Stack trước khi End Lab
# (Chống trừ tiền ngầm vào ngân sách 50 USD của AWS Academy Learner Lab)
# ==============================================================================

set -u

AWS_REGION="${AWS_REGION:-us-east-1}"
LEFTOVER=0

echo "=================================================================="
echo " NT548 Lab 01 — AWS Cleanup Check (TC-07 / SOP 5)"
echo " Time  : $(date -Iseconds)"
echo " Region: ${AWS_REGION}"
echo "=================================================================="

echo ""
echo "=== 1. EC2 Instances chưa terminate ==="
aws ec2 describe-instances --region "${AWS_REGION}" \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table
EC2_COUNT="$(aws ec2 describe-instances --region "${AWS_REGION}" \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'length(Reservations[].Instances[])' --output text)"
echo "Count: ${EC2_COUNT}"
LEFTOVER=$((LEFTOVER + EC2_COUNT))

echo ""
echo "=== 2. NAT Gateways đang hoạt động (NGỐN TIỀN NGẦM!) ==="
aws ec2 describe-nat-gateways --region "${AWS_REGION}" \
  --filter "Name=state,Values=pending,available" \
  --query 'NatGateways[].{ID:NatGatewayId,State:State,VPC:VpcId}' \
  --output table
NAT_COUNT="$(aws ec2 describe-nat-gateways --region "${AWS_REGION}" \
  --filter "Name=state,Values=pending,available" \
  --query 'length(NatGateways)' --output text)"
echo "Count: ${NAT_COUNT}"
LEFTOVER=$((LEFTOVER + NAT_COUNT))

echo ""
echo "=== 3. Elastic IPs chưa giải phóng (TÍNH PHÍ \$0.005/h!) ==="
aws ec2 describe-addresses --region "${AWS_REGION}" \
  --query 'Addresses[].{AllocId:AllocationId,IP:PublicIp,Assoc:AssociationId}' \
  --output table
EIP_COUNT="$(aws ec2 describe-addresses --region "${AWS_REGION}" \
  --query 'length(Addresses)' --output text)"
echo "Count: ${EIP_COUNT}"
LEFTOVER=$((LEFTOVER + EIP_COUNT))

echo ""
echo "=== 4. CloudFormation Stacks của dự án (nt548-*) đang tồn tại ==="
aws cloudformation list-stacks --region "${AWS_REGION}" \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE CREATE_IN_PROGRESS DELETE_FAILED \
  --query 'StackSummaries[?starts_with(StackName, `nt548-`)].{Name:StackName,Status:StackStatus}' \
  --output table
STACK_COUNT="$(aws cloudformation list-stacks --region "${AWS_REGION}" \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE CREATE_IN_PROGRESS DELETE_FAILED \
  --query 'length(StackSummaries[?starts_with(StackName, `nt548-`)])' --output text)"
echo "Count: ${STACK_COUNT}"
LEFTOVER=$((LEFTOVER + STACK_COUNT))

echo ""
echo "=================================================================="
if [[ "${LEFTOVER}" -eq 0 ]]; then
  echo " [PASS] TC-07: SẠCH 100% (0 EC2, 0 NAT GW, 0 EIP, 0 Stack)."
  echo " Bạn có thể yên tâm bấm End Lab!"
  echo "=================================================================="
  exit 0
else
  echo " [WARN] TC-07: Còn ${LEFTOVER} tài nguyên chưa xóa!"
  echo " Hãy chạy 'terraform destroy -auto-approve' hoặc 'aws cloudformation delete-stack'"
  echo " Nếu còn EIP mồ côi: aws ec2 release-address --allocation-id <eipalloc-xxxx>"
  echo "=================================================================="
  exit 1
fi
