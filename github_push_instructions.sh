#!/bin/bash

# GitHub リポジトリへのプッシュ手順

# 1. GitHub CLI で認証
echo "Step 1: GitHub CLI で認証します"
gh auth login

# 2. リポジトリを作成してプッシュ
echo "Step 2: リポジトリを作成してプッシュします"
cd /home/useakat/RNAseqSite
gh repo create useakat/RNAseqSite --source=. --public --push

echo "完了！リポジトリが GitHub にプッシュされました"
echo "https://github.com/useakat/RNAseqSite にアクセスして確認してください"
