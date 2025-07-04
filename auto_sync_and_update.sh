#!/bin/bash

# S3バケット名
S3_BUCKET="html-report-bucket-example"

# ローカルのreportsディレクトリ
REPORTS_DIR="/home/useakat/reports"

# ログファイル
LOG_FILE="/home/useakat/s3_sync.log"

# ログ関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"  # コンソールにも出力
}

log "S3同期スクリプトを開始します"

# S3バケットにreportsディレクトリからすべてのファイルを同期
log "S3バケット $S3_BUCKET にすべてのファイルを同期します"
aws s3 sync $REPORTS_DIR s3://$S3_BUCKET/reports/

# 同期結果をログに記録
if [ $? -eq 0 ]; then
    log "同期が成功しました"
    
    # インデックスを更新
    log "インデックスを更新します"
    /home/useakat/venv/bin/python /home/useakat/generate_index.py
    
    if [ $? -eq 0 ]; then
        log "インデックスの更新が成功しました"
    else
        log "インデックスの更新に失敗しました"
    fi
else
    log "同期に失敗しました"
fi

log "スクリプトを終了します"
