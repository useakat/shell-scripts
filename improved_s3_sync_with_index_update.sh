#!/bin/bash

# S3バケット名
S3_BUCKET="html-report-bucket-example"

# ローカルのreportsディレクトリ
REPORTS_DIR="/home/useakat/reports"

# ログファイル
LOG_FILE="/home/useakat/s3_sync.log"

# 削除されたファイルを記録するファイル
DELETED_FILES="/home/useakat/deleted_files.txt"

# インデックス更新フラグ
INDEX_UPDATE_NEEDED=0

# HTMLファイルが追加されたかのフラグ
HTML_FILES_ADDED=0

# reportsディレクトリが存在しない場合は作成
mkdir -p $REPORTS_DIR

# 削除されたファイルリストが存在しない場合は作成
touch $DELETED_FILES

# ログ関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"  # コンソールにも出力
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
log "ローカルのすべてのファイルリストを取得します"
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
        
        # ファイルの拡張子を取得
        file_extension="${file##*.}"
        
        # HTMLファイルの場合は特別な処理
        if [[ "$file_extension" == "html" ]]; then
            aws s3 cp "$REPORTS_DIR/$file" "s3://$S3_BUCKET/reports/$file" --content-type "text/html"
            HTML_FILES_ADDED=1
        else
            # 拡張子に応じたContent-Typeを設定
            case "$file_extension" in
                css)  content_type="text/css" ;;
                js)   content_type="application/javascript" ;;
                json) content_type="application/json" ;;
                png)  content_type="image/png" ;;
                jpg|jpeg) content_type="image/jpeg" ;;
                gif)  content_type="image/gif" ;;
                svg)  content_type="image/svg+xml" ;;
                pdf)  content_type="application/pdf" ;;
                txt)  content_type="text/plain" ;;
                csv)  content_type="text/csv" ;;
                xml)  content_type="application/xml" ;;
                *)    content_type="application/octet-stream" ;;
            esac
            
            aws s3 cp "$REPORTS_DIR/$file" "s3://$S3_BUCKET/reports/$file" --content-type "$content_type"
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
    /home/useakat/venv/bin/python /home/useakat/generate_index.py
    
    if [ $? -eq 0 ]; then
        log "インデックスの更新が完了しました"
    else
        log "インデックスの更新に失敗しました"
    fi
else
    log "ファイルの変更はありません。インデックスの更新はスキップします"
fi

log "同期が完了しました"
log "スクリプトを終了します"

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
        
        # ファイルの拡張子を取得
        file_extension="${file##*.}"
        
        # HTMLファイルの場合は特別な処理
        if [[ "$file_extension" == "html" ]]; then
            aws s3 cp "$REPORTS_DIR/$file" "s3://$S3_BUCKET/reports/$file" --content-type "text/html"
            HTML_FILES_ADDED=1
        else
            # 拡張子に応じたContent-Typeを設定
            case "$file_extension" in
                css)  content_type="text/css" ;;
                js)   content_type="application/javascript" ;;
                json) content_type="application/json" ;;
                png)  content_type="image/png" ;;
                jpg|jpeg) content_type="image/jpeg" ;;
                gif)  content_type="image/gif" ;;
                svg)  content_type="image/svg+xml" ;;
                pdf)  content_type="application/pdf" ;;
                txt)  content_type="text/plain" ;;
                csv)  content_type="text/csv" ;;
                xml)  content_type="application/xml" ;;
                *)    content_type="application/octet-stream" ;;
            esac
            
            aws s3 cp "$REPORTS_DIR/$file" "s3://$S3_BUCKET/reports/$file" --content-type "$content_type"
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
    
    # HTMLファイルが追加された場合のみインデックスを更新
    if [ $HTML_FILES_ADDED -eq 1 ]; then
        # インデックス生成スクリプトを実行
        python3 /home/ubuntu/generate_index.py
        log "HTMLファイルが追加されたため、インデックスの更新が完了しました"
    else
        log "HTMLファイル以外のファイルのみが追加されたため、インデックスの更新はスキップします"
    fi
else
    log "ファイルの変更はありません。インデックスの更新はスキップします"
fi

log "同期が完了しました"
log "スクリプトを終了します"
