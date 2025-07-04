#!/bin/bash

# S3バケット名
S3_BUCKET="html-report-bucket-example"

# ローカルのreportsディレクトリ
REPORTS_DIR="/home/ubuntu/reports"

# ログファイル
LOG_FILE="/home/ubuntu/s3_sync.log"

# reportsディレクトリが存在しない場合は作成
mkdir -p $REPORTS_DIR

# ログ関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "S3同期スクリプトを開始します"

# AWS CLIがインストールされているか確認
if ! command -v aws &> /dev/null; then
    log "AWS CLIがインストールされていません。インストールします。"
    sudo apt-get update
    sudo apt-get install -y awscli
fi

# S3バケットにreportsディレクトリからすべてのファイルを同期
log "S3バケット $S3_BUCKET にすべてのファイルを同期します"
aws s3 sync $REPORTS_DIR s3://$S3_BUCKET/reports/

# 同期結果をログに記録
if [ $? -eq 0 ]; then
    log "同期が成功しました"
else
    log "同期に失敗しました"
fi

# cronジョブを設定（初回実行時のみ）
if ! crontab -l | grep -q "s3_sync_script.sh"; then
    log "cronジョブを設定します"
    (crontab -l 2>/dev/null; echo "*/1 * * * * /home/ubuntu/s3_sync_script.sh") | crontab -
    log "cronジョブが設定されました"
fi

log "スクリプトを終了します"
