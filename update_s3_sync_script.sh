#!/bin/bash

# S3同期スクリプトを更新して、すべてのファイルタイプを対象にする

# 更新するファイル
SCRIPT_PATH="/home/ubuntu/s3_sync_script.sh"

# バックアップを作成
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cp $SCRIPT_PATH ${SCRIPT_PATH}.bak"

# スクリプトを更新
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "sed -i 's/LOCAL_FILES=\$(find \$REPORTS_DIR -name \"*.html\" -type f | sed \"s|\$REPORTS_DIR\/||\")/LOCAL_FILES=\$(find \$REPORTS_DIR -type f | sed \"s|\$REPORTS_DIR\/||\")/g' $SCRIPT_PATH"

# コンテントタイプの設定を更新
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "sed -i '/aws s3 cp/s/--content-type \"text\/html\"//g' $SCRIPT_PATH"

# 更新されたスクリプトを表示
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cat $SCRIPT_PATH"

# 更新後にテストファイルを再度作成
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "echo 'This is a test file for monitoring - updated' > /home/ubuntu/reports/plots/test6.txt"

echo "S3同期スクリプトを更新し、テストファイルを作成しました。"
