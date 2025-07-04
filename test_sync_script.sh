#!/bin/bash

# S3バケット名（実際のバケット名に置き換える必要があります）
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

# テスト用：S3コマンドをシミュレート
log "テストモード: S3コマンドはシミュレートされます"

# ローカルのすべてのファイルリストを取得
log "ローカルのすべてのファイルリストを取得します"
LOCAL_FILES=$(find $REPORTS_DIR -type f | sed "s|$REPORTS_DIR/||")

# ファイルリストを表示
log "検出されたファイル:"
for file in $LOCAL_FILES; do
    log "- $file"
    
    # ファイルの拡張子を取得
    file_extension="${file##*.}"
    
    # HTMLファイルの場合は特別な処理
    if [[ "$file_extension" == "html" ]]; then
        log "  HTMLファイルが検出されました: $file"
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
        log "  ファイルタイプ: $file_extension, Content-Type: $content_type"
    fi
    
    # ファイルがアップロードされたらインデックス更新フラグをセット
    INDEX_UPDATE_NEEDED=1
done

# インデックスの更新が必要な場合
if [ $INDEX_UPDATE_NEEDED -eq 1 ]; then
    log "ファイルがアップロードされたため、インデックスを更新します"
    
    # HTMLファイルが追加された場合のみインデックスを更新
    if [ $HTML_FILES_ADDED -eq 1 ]; then
        # インデックス生成スクリプトを実行（テスト用にシミュレート）
        log "HTMLファイルが追加されたため、インデックスの更新が必要です"
        log "テストモード: インデックス生成スクリプトを実行します（シミュレーション）"
    else
        log "HTMLファイル以外のファイルのみが追加されたため、インデックスの更新はスキップします"
    fi
else
    log "ファイルの変更はありません。インデックスの更新はスキップします"
fi

log "同期が完了しました"
log "スクリプトを終了します"
