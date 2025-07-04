#!/bin/bash

# 監視対象のディレクトリ
WATCH_DIR="/home/ubuntu/reports"

# S3転送と更新スクリプト
SYNC_SCRIPT="/home/ubuntu/s3_sync_script.sh"

# ログファイル
LOG_FILE="/home/ubuntu/monitor_reports.log"

echo "$(date): reports ディレクトリの監視を開始します..." | tee -a $LOG_FILE

# 無限ループでファイル変更を監視
inotifywait -m -r -e create,moved_to $WATCH_DIR |
while read path action file; do
    echo "$(date): 新しいファイルを検出: $file ($action)" | tee -a $LOG_FILE
    
    # S3転送と reports-tree.html 更新スクリプトを実行
    $SYNC_SCRIPT
    
    # 実行結果をログに記録
    if [ $? -eq 0 ]; then
        echo "$(date): 同期と更新が成功しました" | tee -a $LOG_FILE
    else
        echo "$(date): 同期と更新に失敗しました" | tee -a $LOG_FILE
    fi
    
    # 連続した変更で何度も実行されないよう少し待機
    sleep 2
done
