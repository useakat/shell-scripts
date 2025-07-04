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

# cronジョブを設定して定期的にインデックスを更新
echo "cronジョブを設定します..."
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_PATH $EC2_USERNAME@$PUBLIC_DNS "
(crontab -l 2>/dev/null || echo '') | grep -v 'generate_index.py' | { cat; echo '0 * * * * python3 /home/ubuntu/generate_index.py >> /home/ubuntu/index_update.log 2>&1'; } | crontab -
"

echo "cronジョブが設定されました。インデックスページは1時間ごとに自動更新されます。"

# S3バケットのウェブサイト設定を有効化
echo "S3バケットのウェブサイト設定を有効化します..."
aws s3 website s3://html-report-bucket-example --index-document index.html --error-document error.html

echo "S3バケットのウェブサイト設定が完了しました。"
echo "ウェブサイトURL: http://html-report-bucket-example.s3-website-us-east-1.amazonaws.com/"
