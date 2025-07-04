KEY="RNAseqKey.pem"
IP=107-22-184-215

ssh -i $KEY -o StrictHostKeyChecking=no ubuntu@ec2-${IP}.compute-1.amazonaws.com
