#!/bin/bash

# RNAseqインスタンスのreportsディレクトリのパス
SOURCE_DIR="/path/to/reports"

# S3バケットの宛先パス
S3_BUCKET="html-report-bucket-example"
S3_PREFIX="reports"

# すべてのファイルをS3にコピー
aws s3 sync $SOURCE_DIR s3://$S3_BUCKET/$S3_PREFIX

# ログ出力
echo "$(date): All files synced to S3" >> /var/log/file_sync.log
