#!/bin/bash

# S3バケットの監視と更新スクリプト
# S3でファイルやディレクトリが削除された場合にreports-tree.htmlを更新する

# 更新するファイル
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cat > /home/ubuntu/s3_monitor.sh" << 'EOF'
#!/bin/bash

# S3バケット名
S3_BUCKET="html-report-bucket-example"

# ログファイル
LOG_FILE="/home/ubuntu/s3_monitor.log"

# 前回のファイルリストを保存するファイル
PREVIOUS_FILES="/home/ubuntu/s3_files_list.txt"

# ログ関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "S3監視スクリプトを開始します"

# S3バケットの現在のファイルリストを取得
log "S3バケットの現在のファイルリストを取得します"
aws s3 ls s3://$S3_BUCKET/reports/ --recursive | grep -v "/$" | awk '{print $4}' > /tmp/current_s3_files.txt

# 前回のファイルリストが存在しない場合は作成
if [ ! -f $PREVIOUS_FILES ]; then
    log "前回のファイルリストが存在しないため、現在のリストを保存します"
    cp /tmp/current_s3_files.txt $PREVIOUS_FILES
    exit 0
fi

# 前回のリストと現在のリストを比較
DIFF_OUTPUT=$(diff $PREVIOUS_FILES /tmp/current_s3_files.txt)
if [ -n "$DIFF_OUTPUT" ]; then
    log "S3バケットの内容に変更が検出されました"
    
    # 削除されたファイルがあるか確認
    DELETED_FILES=$(comm -23 $PREVIOUS_FILES /tmp/current_s3_files.txt)
    if [ -n "$DELETED_FILES" ]; then
        log "削除されたファイルを検出しました:"
        echo "$DELETED_FILES" | while read file; do
            log "  - $file"
        done
        
        # インデックスを更新
        log "インデックスを更新します"
        python3 /home/ubuntu/generate_index.py
        log "インデックスの更新が完了しました"
    else
        log "削除されたファイルはありませんでした"
    fi
    
    # 現在のリストを保存
    cp /tmp/current_s3_files.txt $PREVIOUS_FILES
else
    log "S3バケットの内容に変更はありません"
fi

log "S3監視スクリプトを終了します"
EOF

# スクリプトに実行権限を付与
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "chmod +x /home/ubuntu/s3_monitor.sh"

# cronジョブを設定して定期的に実行（5分ごと）
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "crontab -l > /tmp/current_cron"
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "grep -q 's3_monitor.sh' /tmp/current_cron || (echo '*/5 * * * * /home/ubuntu/s3_monitor.sh' >> /tmp/current_cron && crontab /tmp/current_cron)"

# 初回実行
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "/home/ubuntu/s3_monitor.sh"

echo "S3監視スクリプトを設定し、cronジョブを追加しました。5分ごとにS3バケットの変更を監視します。"
