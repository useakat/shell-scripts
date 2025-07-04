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

# インデックス生成スクリプトをEC2インスタンスにコピー
echo "インデックス生成スクリプトをEC2インスタンスにコピーします..."
scp -o StrictHostKeyChecking=no -i $SSH_KEY_PATH /home/useakat/generate_index_fixed.py $EC2_USERNAME@$PUBLIC_DNS:/home/ubuntu/generate_index.py

# スクリプトに実行権限を付与
echo "スクリプトに実行権限を付与します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "chmod +x /home/ubuntu/generate_index.py"

# boto3がインストールされているか確認し、必要に応じてインストール
echo "boto3の確認とインストール..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "if ! python3 -c 'import boto3' 2>/dev/null; then pip3 install boto3 --user; fi"

# スクリプトを実行
echo "インデックス生成スクリプトを実行します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "python3 /home/ubuntu/generate_index.py"

echo "インデックスページの生成と更新が完了しました。"
