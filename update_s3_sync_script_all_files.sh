#!/bin/bash

# S3同期スクリプトを更新して、すべてのファイルタイプを対象にする

# 更新するファイル
SCRIPT_PATH="/home/ubuntu/s3_sync_script.sh"

# バックアップを作成
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cp $SCRIPT_PATH ${SCRIPT_PATH}.bak2"

# スクリプトを更新 - HTMLファイルだけでなくすべてのファイルを対象にする
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cat > $SCRIPT_PATH" << 'EOF'
#!/bin/bash

# S3バケット名
S3_BUCKET="html-report-bucket-example"

# ローカルのreportsディレクトリ
REPORTS_DIR="/home/ubuntu/reports"

# ログファイル
LOG_FILE="/home/ubuntu/s3_sync.log"

# 削除されたファイルを記録するファイル
DELETED_FILES="/home/ubuntu/deleted_files.txt"

# インデックス更新フラグ
INDEX_UPDATE_NEEDED=0

# reportsディレクトリが存在しない場合は作成
mkdir -p $REPORTS_DIR

# 削除されたファイルリストが存在しない場合は作成
touch $DELETED_FILES

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

# S3バケットの現在のファイルリストを取得
log "S3バケットの現在のファイルリストを取得します"
S3_FILES=$(aws s3 ls s3://$S3_BUCKET/reports/ --recursive | grep -v "/$" | awk '{print $4}')

# ローカルのすべてのファイルリストを取得
log "ローカルのファイルリストを取得します"
LOCAL_FILES=$(find $REPORTS_DIR -type f | sed "s|$REPORTS_DIR/||")

# S3にアップロードするファイルを決定
for file in $LOCAL_FILES; do
    # 削除されたファイルリストにあるかチェック
    if grep -q "^reports/$file$" $DELETED_FILES; then
        log "ファイル $file は削除されたファイルリストにあるため、スキップします"
        continue
    fi
    
    # S3にファイルが存在するかチェック
    if ! echo "$S3_FILES" | grep -q "^reports/$file$"; then
        # S3にファイルが存在しない場合、アップロード
        log "ファイル $file をS3にアップロードします"
        
        # ファイルの拡張子に基づいてContent-Typeを設定
        extension="${file##*.}"
        content_type=""
        
        case "$extension" in
            html)
                content_type="text/html"
                ;;
            txt)
                content_type="text/plain"
                ;;
            json)
                content_type="application/json"
                ;;
            png)
                content_type="image/png"
                ;;
            jpg|jpeg)
                content_type="image/jpeg"
                ;;
            pdf)
                content_type="application/pdf"
                ;;
            *)
                # デフォルトのContent-Type
                content_type="application/octet-stream"
                ;;
        esac
        
        # Content-Typeを指定してアップロード
        if [ -n "$content_type" ]; then
            aws s3 cp "$REPORTS_DIR/$file" "s3://$S3_BUCKET/reports/$file" --content-type "$content_type"
        else
            aws s3 cp "$REPORTS_DIR/$file" "s3://$S3_BUCKET/reports/$file"
        fi
        
        # ファイルがアップロードされたらインデックス更新フラグをセット
        INDEX_UPDATE_NEEDED=1
    fi
done

# S3から削除されたファイルを検出して記録
for file in $LOCAL_FILES; do
    s3_path="reports/$file"
    if ! echo "$S3_FILES" | grep -q "^$s3_path$" && ! grep -q "^$s3_path$" $DELETED_FILES; then
        # S3にファイルが存在せず、かつ削除リストにない場合、削除リストに追加
        log "ファイル $file はS3から削除されました。削除リストに追加します"
        echo "$s3_path" >> $DELETED_FILES
    fi
done

# インデックスの更新が必要な場合
if [ $INDEX_UPDATE_NEEDED -eq 1 ]; then
    log "ファイルがアップロードされたため、インデックスを更新します"
    # インデックス生成スクリプトを実行
    python3 /home/ubuntu/generate_index.py
    log "インデックスの更新が完了しました"
else
    log "ファイルの変更はありません。インデックスの更新はスキップします"
fi

log "同期が完了しました"
log "スクリプトを終了します"
EOF

# 更新されたスクリプトを表示
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "cat $SCRIPT_PATH"

# 更新後にテストファイルを再度作成
ssh -i RNAseqKey.pem ubuntu@ec2-107-22-184-215.compute-1.amazonaws.com "echo 'This is a test file for monitoring - updated' > /home/ubuntu/reports/plots/test6.txt"

echo "S3同期スクリプトを更新し、テストファイルを作成しました。"
