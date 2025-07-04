#!/bin/bash

# Lambda関数とS3イベント通知を設定するスクリプト

# 変数設定
LAMBDA_FUNCTION_NAME="UpdateReportsTreeHtml"
S3_BUCKET="html-report-bucket-example"
REGION="us-east-1"  # S3バケットと同じリージョンを指定
ROLE_NAME="LambdaS3UpdateRole"

echo "Lambda関数とS3イベント通知の設定を開始します..."

# Lambda関数のコードをZIPに圧縮
echo "Lambda関数のコードを圧縮しています..."
zip -j lambda_function.zip /home/useakat/lambda_function.py

# IAMロールの作成
echo "IAMロールを作成しています..."
ROLE_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

# ロールが存在するか確認
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text 2>/dev/null || echo "")

if [ -z "$ROLE_ARN" ]; then
  echo "新しいIAMロールを作成します: $ROLE_NAME"
  ROLE_RESPONSE=$(aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document "$ROLE_POLICY")
  ROLE_ARN=$(echo $ROLE_RESPONSE | jq -r '.Role.Arn')
  
  # ロールにポリシーをアタッチ
  echo "ロールにポリシーをアタッチしています..."
  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  
  # ロールが有効になるまで少し待機
  echo "ロールが有効になるまで待機しています..."
  sleep 10
else
  echo "既存のIAMロールを使用します: $ROLE_NAME"
fi

# Lambda関数の作成
echo "Lambda関数を作成しています: $LAMBDA_FUNCTION_NAME"

# 関数が既に存在するか確認
FUNCTION_EXISTS=$(aws lambda get-function --function-name $LAMBDA_FUNCTION_NAME 2>/dev/null || echo "")

if [ -z "$FUNCTION_EXISTS" ]; then
  echo "新しいLambda関数を作成します..."
  aws lambda create-function \
    --function-name $LAMBDA_FUNCTION_NAME \
    --runtime python3.9 \
    --handler lambda_function.lambda_handler \
    --role $ROLE_ARN \
    --zip-file fileb://lambda_function.zip \
    --timeout 30 \
    --region $REGION
else
  echo "既存のLambda関数を更新します..."
  aws lambda update-function-code \
    --function-name $LAMBDA_FUNCTION_NAME \
    --zip-file fileb://lambda_function.zip \
    --region $REGION
fi

# Lambda関数のARNを取得
LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_FUNCTION_NAME --query 'Configuration.FunctionArn' --output text --region $REGION)
echo "Lambda関数ARN: $LAMBDA_ARN"

# S3バケットにイベント通知を設定
echo "S3バケットにイベント通知を設定しています..."

# Lambda関数にS3からの呼び出し権限を付与
echo "Lambda関数にS3からの呼び出し権限を付与しています..."
aws lambda add-permission \
  --function-name $LAMBDA_FUNCTION_NAME \
  --statement-id s3-trigger \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::$S3_BUCKET \
  --source-account $(aws sts get-caller-identity --query 'Account' --output text) \
  --region $REGION

# S3イベント通知の設定
echo "S3イベント通知を設定しています..."
NOTIFICATION_CONFIG='{
  "LambdaFunctionConfigurations": [
    {
      "Id": "UpdateReportsTreeHtmlEvent",
      "LambdaFunctionArn": "'$LAMBDA_ARN'",
      "Events": ["s3:ObjectRemoved:*", "s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "reports/"
            }
          ]
        }
      }
    }
  ]
}'

aws s3api put-bucket-notification-configuration \
  --bucket $S3_BUCKET \
  --notification-configuration "$NOTIFICATION_CONFIG"

echo "セットアップが完了しました。S3バケット内のreportsディレクトリでファイルが削除または追加されると、Lambda関数が実行されreports-tree.htmlが更新されます。"
