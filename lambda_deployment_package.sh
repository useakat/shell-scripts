#!/bin/bash

# 作業ディレクトリを作成
mkdir -p /tmp/lambda_package
cd /tmp/lambda_package

# 必要なライブラリをインストール
pip install paramiko -t .

# Lambda関数のコードをコピー
cp /home/useakat/lambda_function.py .

# ZIPファイルを作成
zip -r ../lambda_function.zip .

echo "Lambda deployment package created at /tmp/lambda_function.zip"
