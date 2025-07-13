#!/bin/bash

echo "🔍 Troubleshooting Proxy Server Connection"
echo "=========================================="

# Step 1: Check if proxy server is running
echo "1. Checking if proxy server is running..."
if sudo ss -tulpn | grep -q ":3000"; then
    echo "✅ Proxy server is running on port 3000"
    sudo ss -tulpn | grep ":3000"
else
    echo "❌ Proxy server is NOT running on port 3000"
    echo "Let's check PM2 status..."
    pm2 list
    echo ""
    echo "PM2 logs for planapi-proxy:"
    pm2 logs planapi-proxy --lines 20
fi

echo ""

# Step 2: Check firewall status
echo "2. Checking firewall status..."
if systemctl is-active --quiet firewalld; then
    echo "✅ Firewalld is running"
    echo "Checking port 3000 rules..."
    sudo firewall-cmd --list-ports | grep -q "3000/tcp"
    if [ $? -eq 0 ]; then
        echo "✅ Port 3000 is open in firewall"
    else
        echo "❌ Port 3000 is NOT open in firewall"
        echo "Opening port 3000..."
        sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent
        sudo firewall-cmd --reload
        echo "✅ Port 3000 opened"
    fi
else
    echo "⚠️  Firewalld is not running"
    echo "Starting firewalld..."
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent
    sudo firewall-cmd --reload
    echo "✅ Firewalld started and port 3000 opened"
fi

echo ""

# Step 3: Test local connection
echo "3. Testing local connection..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Local connection works"
    curl -s http://localhost:3000/health | head -3
else
    echo "❌ Local connection failed"
fi

echo ""

# Step 4: Test external connection
echo "4. Testing external connection..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Public IP: $PUBLIC_IP"

if curl -s http://$PUBLIC_IP:3000/health > /dev/null; then
    echo "✅ External connection works"
    curl -s http://$PUBLIC_IP:3000/health | head -3
else
    echo "❌ External connection failed"
    echo "This is likely an AWS Security Group issue"
fi

echo ""

# Step 5: Start/restart proxy if needed
echo "5. Starting/restarting proxy server..."
cd ~/planapi-proxy

# Kill any existing process
pkill -f "node server.js"
pm2 stop planapi-proxy 2>/dev/null || true
pm2 delete planapi-proxy 2>/dev/null || true

# Start fresh
echo "Starting proxy server..."
pm2 start server.js --name planapi-proxy
pm2 save

echo ""
echo "6. Final status check..."
sleep 3
pm2 list
echo ""

if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Proxy server is now running successfully"
    echo "🌐 Health check: http://$PUBLIC_IP:3000/health"
    echo "📱 API endpoint: http://$PUBLIC_IP:3000/api/planapi/Mobile/OperatorFetchNew"
else
    echo "❌ Proxy server still not responding"
    echo "Check PM2 logs: pm2 logs planapi-proxy"
fi

echo ""
echo "🔧 AWS Security Group Configuration:"
echo "If external connection still fails, configure AWS Security Group:"
echo "1. Go to AWS Console → EC2 → Security Groups"
echo "2. Find your instance's security group"
echo "3. Add inbound rule:"
echo "   - Type: Custom TCP"
echo "   - Port: 3000"
echo "   - Source: 0.0.0.0/0 (or your specific IP)"
echo "4. Save the rule" 