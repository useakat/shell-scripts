#!/bin/bash

# SSHキーのパス（実際のパスに変更してください）
SSH_KEY_PATH="~/.ssh/rnaseq-instance-key.pem"

# SSHキーの内容を取得
SSH_KEY_CONTENT=$(cat $SSH_KEY_PATH)

# Parameter Storeに保存（SecureStringとして）
aws ssm put-parameter \
    --name "/ec2/ssh-key/rnaseq-instance" \
    --type "SecureString" \
    --value "$SSH_KEY_CONTENT" \
    --overwrite \
    --region us-east-1
