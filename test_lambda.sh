#!/bin/bash

# CloudWatch Alarm event payload
EVENT='{
  "version": "0",
  "id": "12345678-1234-1234-1234-123456789012",
  "detail-type": "CloudWatch Alarm State Change",
  "source": "aws.cloudwatch",
  "account": "353115813630",
  "time": "2025-06-08T06:00:00Z",
  "region": "us-east-1",
  "resources": [
    "arn:aws:cloudwatch:us-east-1:353115813630:alarm:Idle-alarm-EC2-stop"
  ],
  "detail": {
    "alarmName": "Idle-alarm-EC2-stop",
    "state": {
      "value": "ALARM",
      "reason": "テスト通知の確認",
      "reasonData": "{\"evaluatedDatapoints\":[]}",
      "timestamp": "2025-06-08T06:00:00Z"
    },
    "previousState": {
      "value": "INSUFFICIENT_DATA",
      "reason": "Insufficient Data",
      "timestamp": "2025-06-08T05:51:37Z"
    },
    "configuration": {
      "description": "",
      "metrics": [
        {
          "id": "m1",
          "metricStat": {
            "metric": {
              "namespace": "AWS/EC2",
              "name": "CPUUtilization",
              "dimensions": {
                "InstanceId": "i-01166463ddfaed9eb"
              }
            },
            "period": 300,
            "stat": "Average"
          },
          "returnData": true
        }
      ]
    }
  }
}'

# Invoke Lambda function with the test event
echo "Invoking Lambda function with test CloudWatch Alarm event..."
aws lambda invoke \
  --function-name CloudWatchAlarmEmailNotifier \
  --payload "$EVENT" \
  --cli-binary-format raw-in-base64-out \
  response.json

# Display the response
echo -e "\nLambda response:"
cat response.json

# Check CloudWatch Logs
echo -e "\nTo check CloudWatch Logs for more details, run:"
echo "aws logs describe-log-streams --log-group-name /aws/lambda/CloudWatchAlarmEmailNotifier --region us-east-1"
echo "aws logs get-log-events --log-group-name /aws/lambda/CloudWatchAlarmEmailNotifier --log-stream-name <latest-log-stream> --region us-east-1"
