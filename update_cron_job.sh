#!/bin/bash

# EC2インスタンスの情報
EC2_INSTANCE_ID="i-01166463ddfaed9eb"
EC2_USERNAME="ubuntu"
SSH_KEY_PATH="/home/useakat/RNAseqKey.pem"

# EC2インスタンスのパブリックDNSを取得
PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query "Reservations[0].Instances[0].PublicDnsName" --output text --region us-east-1)

if [ -z "$PUBLIC_DNS" ] || [ "$PUBLIC_DNS" == "None" ]; then
  echo "EC2インスタンスのパブリックDNSが見つかりません。"
  exit 1
fi

echo "EC2パブリックDNS: $PUBLIC_DNS"

# 1時間ごとのインデックス更新cronジョブを削除（既に同期スクリプトで更新されるため）
echo "cronジョブを更新します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "
(crontab -l 2>/dev/null | grep -v 'generate_index.py') | crontab -
"

echo "cronジョブが更新されました。"
