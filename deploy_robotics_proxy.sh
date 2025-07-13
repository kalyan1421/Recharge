#!/bin/bash

# Deploy updated proxy server with Robotics Exchange API support to AWS EC2
# Usage: ./deploy_robotics_proxy.sh

set -e

# Configuration
EC2_HOST="56.228.11.165"
EC2_USER="ec2-user"
KEY_FILE="rechager.pem"
REMOTE_DIR="/home/ec2-user/proxy-server"
PORT=3001

echo "🚀 Deploying updated proxy server with Robotics Exchange API support..."

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Error: Key file '$KEY_FILE' not found!"
    echo "Please ensure the key file is in the current directory."
    exit 1
fi

# Set correct permissions for key file
chmod 400 "$KEY_FILE"

echo "📦 Copying updated proxy server files to EC2..."

# Copy the updated proxy server file
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no aws_proxy_server.js "$EC2_USER@$EC2_HOST:$REMOTE_DIR/"

echo "🔄 Restarting proxy server on EC2..."

# SSH into EC2 and restart the proxy server
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" << 'EOF'
cd /home/ec2-user/proxy-server

# Stop existing proxy server
echo "Stopping existing proxy server..."
pkill -f "node aws_proxy_server.js" || true
sleep 2

# Install any missing dependencies
echo "Installing dependencies..."
npm install express axios cors express-rate-limit helmet dotenv

# Start the updated proxy server
echo "Starting updated proxy server..."
nohup node aws_proxy_server.js > proxy.log 2>&1 &

# Wait a moment for server to start
sleep 3

# Check if server is running
if pgrep -f "node aws_proxy_server.js" > /dev/null; then
    echo "✅ Proxy server started successfully!"
    echo "Server is running on port 3001"
    
    # Test the health endpoint
    echo "Testing health endpoint..."
    curl -s http://localhost:3001/health | head -5
else
    echo "❌ Failed to start proxy server"
    echo "Check the logs:"
    tail -20 proxy.log
    exit 1
fi

echo "📊 Current server status:"
ps aux | grep "node aws_proxy_server.js" | grep -v grep
EOF

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Proxy server details:"
echo "  - Host: $EC2_HOST"
echo "  - Port: $PORT"
echo "  - Plan API endpoint: http://$EC2_HOST:$PORT/api/planapi/*"
echo "  - Robotics API endpoint: http://$EC2_HOST:$PORT/api/robotics/*"
echo "  - Health check: http://$EC2_HOST:$PORT/health"
echo ""
echo "🔧 To check logs:"
echo "  ssh -i $KEY_FILE $EC2_USER@$EC2_HOST 'tail -f /home/ec2-user/proxy-server/proxy.log'"
echo ""
echo "🛠️  To restart server:"
echo "  ssh -i $KEY_FILE $EC2_USER@$EC2_HOST 'cd /home/ec2-user/proxy-server && pkill -f \"node aws_proxy_server.js\" && nohup node aws_proxy_server.js > proxy.log 2>&1 &'" 