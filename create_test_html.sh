#!/bin/bash

# EC2インスタンスの情報
EC2_INSTANCE_ID="i-01166463ddfaed9eb"
EC2_USERNAME="ubuntu"
SSH_KEY_PATH="/home/useakat/.ssh/rnaseq-instance-key"

# EC2インスタンスのパブリックDNSを取得
PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query "Reservations[0].Instances[0].PublicDnsName" --output text --region us-east-1)

if [ -z "$PUBLIC_DNS" ] || [ "$PUBLIC_DNS" == "None" ]; then
  echo "EC2インスタンスのパブリックDNSが見つかりません。"
  exit 1
fi

echo "EC2パブリックDNS: $PUBLIC_DNS"

# reportsディレクトリが存在するか確認し、なければ作成
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "mkdir -p reports"

# テスト用HTMLファイルを作成
TIMESTAMP=$(date +%Y%m%d%H%M%S)
HTML_CONTENT="<html><head><title>Test HTML $TIMESTAMP</title></head><body><h1>Test HTML File</h1><p>This is a test HTML file created at $TIMESTAMP</p></body></html>"

# HTMLファイルをEC2インスタンスに転送
echo "$HTML_CONTENT" | ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "cat > reports/test_$TIMESTAMP.html"

echo "テスト用HTMLファイル reports/test_$TIMESTAMP.html を作成しました。"
