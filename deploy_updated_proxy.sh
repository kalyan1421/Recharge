#!/bin/bash

echo "🚀 Deploying updated proxy server..."

# Copy the updated server file to AWS
scp -i /Users/kalyan/Downloads/rechager.pem updated_proxy_server.js ubuntu@56.228.11.165:/home/ubuntu/proxy-server/server.js

# Connect to AWS and restart the server
ssh -i /Users/kalyan/Downloads/rechager.pem ubuntu@56.228.11.165 << 'REMOTE_SCRIPT'
cd /home/ubuntu/proxy-server

# Stop the current server
pm2 stop recharge-proxy

# Start the updated server
pm2 start server.js --name "recharge-proxy"

# Save PM2 configuration
pm2 save

# Check status
pm2 status

# Show logs
pm2 logs recharge-proxy --lines 20
REMOTE_SCRIPT

echo "✅ Updated proxy server deployed!"
echo "🔗 Test the health endpoint: http://56.228.11.165/health"
echo "🔗 Test recharge endpoint: http://56.228.11.165/api/recharge?mobileno=9063290012&operatorcode=11&circle=49&amount=10&requestid=TEST123"
