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

# スクリプトをEC2インスタンスにコピー
echo "同期スクリプトをEC2インスタンスにコピーします..."
scp -o StrictHostKeyChecking=no -i $SSH_KEY_PATH /home/useakat/ec2_s3_sync_script.sh $EC2_USERNAME@$PUBLIC_DNS:/home/ubuntu/s3_sync_script.sh

# スクリプトに実行権限を付与
echo "スクリプトに実行権限を付与します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "chmod +x /home/ubuntu/s3_sync_script.sh"

# reportsディレクトリを作成
echo "reportsディレクトリを作成します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "mkdir -p /home/ubuntu/reports"

# テスト用HTMLファイルを作成
echo "テスト用HTMLファイルを作成します..."
TIMESTAMP=$(date +%Y%m%d%H%M%S)
HTML_CONTENT="<html><head><title>Test HTML $TIMESTAMP</title></head><body><h1>Test HTML File</h1><p>This is a test HTML file created at $TIMESTAMP</p></body></html>"

ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "echo '$HTML_CONTENT' > /home/ubuntu/reports/test_$TIMESTAMP.html"

# AWS CLIがインストールされているか確認し、必要に応じてインストール
echo "AWS CLIの確認とインストール..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "if ! command -v aws &> /dev/null; then sudo apt-get update && sudo apt-get install -y awscli; fi"

# EC2インスタンスにIAMロールがアタッチされていない場合、AWS認証情報を設定
echo "AWS認証情報を設定します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "mkdir -p ~/.aws"

# AWS認証情報を設定
cat << EOF | ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "cat > ~/.aws/credentials"
[default]
aws_access_key_id = $(aws configure get aws_access_key_id)
aws_secret_access_key = $(aws configure get aws_secret_access_key)
aws_session_token = $(aws configure get aws_session_token)
EOF

cat << EOF | ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "cat > ~/.aws/config"
[default]
region = us-east-1
output = json
EOF

# cronジョブを設定
echo "cronジョブを設定します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "(crontab -l 2>/dev/null || echo '') | grep -v 's3_sync_script.sh' | { cat; echo '*/1 * * * * /home/ubuntu/s3_sync_script.sh'; } | crontab -"

# スクリプトを実行
echo "同期スクリプトを実行します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "/home/ubuntu/s3_sync_script.sh"

echo "デプロイが完了しました。"
