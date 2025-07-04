#!/bin/bash

# change_instance_type.sh
# AWS EC2インスタンスタイプを変更するスクリプト

REGION="us-east-1"  # 必要に応じてリージョンを変更

print_help() {
      cat <<EOF
OF
Usage: $0 <new-instance-type>

Changes the EC2 instance type for the specified instance.

Arguments:
  <new-instance-type>   New instance type to apply (e.g., t3.medium)

Options:
  -h, --help            Show this help message and exit

Example:
  $0 t3.medium

Note:
  The instance will be stopped during the type change and restarted afterward.
  Make sure that the instance is in a state that allows stopping.
EOF
}

# ヘルプオプションの処理
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    print_help
    exit 0
fi

EOF

INSTANCE_ID=i-01166463ddfaed9eb
NEW_TYPE=$1

if [ -z "$INSTANCE_ID" ] || [ -z "$NEW_TYPE" ]; then
    echo "Usage: $0 <new-instance-type>"
    exit 1
fi

echo "Stopping instance $INSTANCE_ID..."
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --region $REGION

echo "Modifying instance type to $NEW_TYPE..."
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type "{\"Value\": \"$NEW_TYPE\"}" --region $REGION

echo "Starting instance $INSTANCE_ID..."
aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

echo "Instance $INSTANCE_ID has been changed to type $NEW_TYPE and is now running."
