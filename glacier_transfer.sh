#!/bin/bash

# S3 Glacier Flexible Retrieval 転送スクリプト
# EC2インスタンスのdataフォルダ内の*.fq.gzファイルをS3 Glacierに転送

# 設定
EC2_INSTANCE="ec2-107-22-184-215.compute-1.amazonaws.com"
SSH_KEY="RNAseqKey.pem"
SOURCE_DIR="/home/ubuntu/data"
S3_BUCKET="rnaseq-data-archive-20250614"
S3_PREFIX="fastq"
LOG_FILE="s3_transfer_$(date +%Y%m%d_%H%M%S).log"

echo "$(date): S3 Glacier Flexible Retrieval 転送計画を作成します" | tee -a $LOG_FILE
echo "EC2インスタンス: $EC2_INSTANCE" | tee -a $LOG_FILE
echo "ソースディレクトリ: $SOURCE_DIR" | tee -a $LOG_FILE
echo "転送先バケット: $S3_BUCKET/$S3_PREFIX/" | tee -a $LOG_FILE
echo "ストレージクラス: GLACIER" | tee -a $LOG_FILE
echo "アクセス設定: private" | tee -a $LOG_FILE

# EC2インスタンスに転送準備スクリプトを作成
echo "EC2インスタンスに転送準備スクリプトを作成しています..." | tee -a $LOG_FILE

ssh -i $SSH_KEY ubuntu@$EC2_INSTANCE "cat > ~/prepare_glacier_transfer.sh" << 'EOF'
#!/bin/bash

# 設定
SOURCE_DIR="/home/ubuntu/data"
S3_BUCKET="rnaseq-data-archive-20250614"
S3_PREFIX="fastq"
LOG_FILE="s3_transfer_$(date +%Y%m%d_%H%M%S).log"

echo "$(date): S3 Glacier Flexible Retrieval 転送計画を作成します" | tee -a $LOG_FILE
echo "ソースディレクトリ: $SOURCE_DIR" | tee -a $LOG_FILE
echo "転送先バケット: $S3_BUCKET/$S3_PREFIX/" | tee -a $LOG_FILE
echo "ストレージクラス: GLACIER" | tee -a $LOG_FILE
echo "アクセス設定: private" | tee -a $LOG_FILE

# ファイル数とサイズを確認
echo "転送対象ファイルを分析しています..." | tee -a $LOG_FILE
FILE_COUNT=$(find $SOURCE_DIR -name "*.fq.gz" 2>/dev/null | wc -l)
if [ $FILE_COUNT -eq 0 ]; then
  echo "警告: $SOURCE_DIR に *.fq.gz ファイルが見つかりません。パスを確認してください。" | tee -a $LOG_FILE
  exit 1
fi

# 合計サイズを計算
TOTAL_SIZE_BYTES=$(find $SOURCE_DIR -name "*.fq.gz" -type f -exec du -b {} \; 2>/dev/null | awk '{total += $1} END {print total}')
TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE_BYTES / 1024 / 1024 / 1024" | bc)

echo "転送するファイル: $FILE_COUNT 個 (合計サイズ約 ${TOTAL_SIZE_GB}GB)" | tee -a $LOG_FILE

# 転送コマンドの生成
TRANSFER_CMD="aws s3 cp $SOURCE_DIR/ s3://$S3_BUCKET/$S3_PREFIX/ --recursive --exclude \"*\" --include \"*.fq.gz\" --storage-class GLACIER --acl private"

echo -e "\n転送に使用するコマンド:" | tee -a $LOG_FILE
echo "$TRANSFER_CMD" | tee -a $LOG_FILE

# 料金の見積もり
STORAGE_COST=$(echo "scale=2; $TOTAL_SIZE_GB * 0.004" | bc)
RETRIEVAL_COST_STANDARD=$(echo "scale=2; $TOTAL_SIZE_GB * 0.01" | bc)
RETRIEVAL_COST_EXPEDITED=$(echo "scale=2; $TOTAL_SIZE_GB * 0.03" | bc)
RETRIEVAL_COST_BULK=$(echo "scale=2; $TOTAL_SIZE_GB * 0.0025" | bc)

echo -e "\n料金の見積もり:" | tee -a $LOG_FILE
echo "ストレージ料金 (月額): 約 \$$STORAGE_COST" | tee -a $LOG_FILE
echo "データ取り出し料金 (1回あたり):" | tee -a $LOG_FILE
echo "  - 迅速取り出し (1-5分): 約 \$$RETRIEVAL_COST_EXPEDITED" | tee -a $LOG_FILE
echo "  - 標準取り出し (3-5時間): 約 \$$RETRIEVAL_COST_STANDARD" | tee -a $LOG_FILE
echo "  - バルク取り出し (5-12時間): 約 \$$RETRIEVAL_COST_BULK" | tee -a $LOG_FILE

# 転送時間の見積もり
# 仮定: 平均アップロード速度 50 MB/秒
UPLOAD_SPEED_MBPS=50
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE_BYTES / 1024 / 1024" | bc)
ESTIMATED_TIME_SEC=$(echo "scale=2; $TOTAL_SIZE_MB / $UPLOAD_SPEED_MBPS" | bc)
ESTIMATED_TIME_MIN=$(echo "scale=2; $ESTIMATED_TIME_SEC / 60" | bc)
ESTIMATED_TIME_HOUR=$(echo "scale=2; $ESTIMATED_TIME_MIN / 60" | bc)

echo -e "\n転送時間の見積もり:" | tee -a $LOG_FILE
echo "  - 秒数: 約 ${ESTIMATED_TIME_SEC}秒" | tee -a $LOG_FILE
echo "  - 分数: 約 ${ESTIMATED_TIME_MIN}分" | tee -a $LOG_FILE
echo "  - 時間: 約 ${ESTIMATED_TIME_HOUR}時間" | tee -a $LOG_FILE
echo "  (注: 実際の転送速度はネットワーク状況により異なります)" | tee -a $LOG_FILE

echo -e "\n実行手順:" | tee -a $LOG_FILE
echo "1. 以下のコマンドでバックグラウンドで転送を実行（SSH切断後も継続）:" | tee -a $LOG_FILE
echo "   nohup $TRANSFER_CMD > transfer.log 2>&1 &" | tee -a $LOG_FILE
echo "2. 転送状況の確認:" | tee -a $LOG_FILE
echo "   tail -f transfer.log" | tee -a $LOG_FILE
echo "3. 転送完了後の確認:" | tee -a $LOG_FILE
echo "   aws s3 ls s3://$S3_BUCKET/$S3_PREFIX/ --recursive | grep \".fq.gz\" | wc -l" | tee -a $LOG_FILE

echo -e "\n注意事項:" | tee -a $LOG_FILE
echo "- Glacier Flexible Retrieval はデータ取り出しに時間がかかります（標準取り出しで3-5時間）" | tee -a $LOG_FILE
echo "- 最小保存期間は90日間です。早期削除すると残りの期間の料金が発生します" | tee -a $LOG_FILE
echo "- 大量のデータを取り出す場合は、事前に計画を立てることをお勧めします" | tee -a $LOG_FILE
echo "- 転送されたデータは自動的にEC2から削除されません。手動で削除する必要があります" | tee -a $LOG_FILE

echo -e "\n$(date): 転送計画の作成が完了しました" | tee -a $LOG_FILE
echo "実際の転送を開始するには、上記の実行手順に従ってください" | tee -a $LOG_FILE
EOF

# スクリプトに実行権限を付与
ssh -i $SSH_KEY ubuntu@$EC2_INSTANCE "chmod +x ~/prepare_glacier_transfer.sh"

# 転送準備スクリプトを実行
echo "転送準備スクリプトを実行しています..." | tee -a $LOG_FILE
ssh -i $SSH_KEY ubuntu@$EC2_INSTANCE "~/prepare_glacier_transfer.sh"

echo -e "\n転送準備が完了しました。" | tee -a $LOG_FILE
echo "実際の転送を開始するには、EC2インスタンスに接続して以下のコマンドを実行してください:" | tee -a $LOG_FILE
echo "ssh -i $SSH_KEY ubuntu@$EC2_INSTANCE" | tee -a $LOG_FILE
echo "nohup aws s3 cp $SOURCE_DIR/ s3://$S3_BUCKET/$S3_PREFIX/ --recursive --exclude \"*\" --include \"*.fq.gz\" --storage-class GLACIER --acl private > transfer.log 2>&1 &" | tee -a $LOG_FILE
