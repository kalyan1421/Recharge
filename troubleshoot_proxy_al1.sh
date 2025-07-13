#!/bin/bash

echo "🔍 Troubleshooting Proxy Server Connection (Amazon Linux 1)"
echo "=========================================================="

# Step 1: Check if proxy server is running
echo "1. Checking if proxy server is running..."
if netstat -tlnp | grep -q ":3000"; then
    echo "✅ Proxy server is running on port 3000"
    netstat -tlnp | grep ":3000"
else
    echo "❌ Proxy server is NOT running on port 3000"
    echo "Let's check if PM2 is installed..."
    if command -v pm2 >/dev/null 2>&1; then
        echo "✅ PM2 is installed"
        pm2 list
        echo ""
        echo "PM2 logs for planapi-proxy:"
        pm2 logs planapi-proxy --lines 20
    else
        echo "❌ PM2 is not installed"
        echo "Let's check if Node.js process is running..."
        ps aux | grep -v grep | grep "node server.js"
    fi
fi

echo ""

# Step 2: Check iptables (Amazon Linux 1 uses iptables instead of firewalld)
echo "2. Checking iptables firewall..."
if sudo iptables -L INPUT -n | grep -q "3000"; then
    echo "✅ Port 3000 rule exists in iptables"
else
    echo "❌ Port 3000 is not open in iptables"
    echo "Opening port 3000..."
    sudo iptables -I INPUT -p tcp --dport 3000 -j ACCEPT
    sudo service iptables save 2>/dev/null || echo "Note: iptables save not available"
    echo "✅ Port 3000 opened in iptables"
fi

echo ""

# Step 3: Test local connection
echo "3. Testing local connection..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Local connection works"
    curl -s http://localhost:3000/health
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
    curl -s http://$PUBLIC_IP:3000/health
else
    echo "❌ External connection failed"
    echo "This is likely an AWS Security Group issue"
fi

echo ""

# Step 5: Check if Node.js and npm are installed
echo "5. Checking Node.js installation..."
if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js is installed: $(node --version)"
else
    echo "❌ Node.js is not installed"
    echo "Installing Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    source ~/.bashrc
    nvm install 16
    nvm use 16
fi

if command -v npm >/dev/null 2>&1; then
    echo "✅ npm is installed: $(npm --version)"
else
    echo "❌ npm is not installed"
fi

echo ""

# Step 6: Set up proxy directory and install dependencies
echo "6. Setting up proxy server..."
mkdir -p ~/planapi-proxy
cd ~/planapi-proxy

# Create package.json
cat > package.json << 'EOF'
{
  "name": "planapi-proxy",
  "version": "1.0.0",
  "description": "Proxy server for PlanAPI",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "http-proxy-middleware": "^2.0.6",
    "cors": "^2.8.5"
  }
}
EOF

# Install dependencies
echo "Installing dependencies..."
npm install

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    server: 'PlanAPI Proxy',
    version: '1.0.0'
  });
});

// Proxy for Plan API
const planApiProxy = createProxyMiddleware({
  target: 'https://planapi.in',
  changeOrigin: true,
  pathRewrite: {
    '^/api/planapi': '/api'
  },
  onProxyReq: (proxyReq, req, res) => {
    // Remove forwarding headers
    proxyReq.removeHeader('x-forwarded-for');
    proxyReq.removeHeader('x-forwarded-host');
    proxyReq.removeHeader('x-forwarded-proto');
    console.log('Proxying to:', proxyReq.path);
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err.message);
    res.status(500).json({ error: 'Proxy error', message: err.message });
  }
});

app.use('/api/planapi', planApiProxy);

app.get('/', (req, res) => {
  res.json({
    message: 'PlanAPI Proxy Server',
    endpoints: {
      health: '/health',
      planapi: '/api/planapi/Mobile/OperatorFetchNew'
    }
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Proxy server running on port ${PORT}`);
});
EOF

echo ""

# Step 7: Start the server
echo "7. Starting proxy server..."
# Kill any existing process
pkill -f "node server.js" 2>/dev/null || true

# Start in background
nohup node server.js > proxy.log 2>&1 &
echo "Server started in background"

# Wait a moment
sleep 3

echo ""

# Step 8: Final test
echo "8. Final connection test..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Proxy server is running successfully!"
    echo "🌐 Health check: http://$PUBLIC_IP:3000/health"
    echo "📱 API endpoint: http://$PUBLIC_IP:3000/api/planapi/Mobile/OperatorFetchNew"
    echo ""
    echo "Response from health check:"
    curl -s http://localhost:3000/health
else
    echo "❌ Proxy server still not responding"
    echo "Check the logs:"
    tail -20 ~/planapi-proxy/proxy.log
fi

echo ""
echo "🔧 If external connection still fails:"
echo "1. Configure AWS Security Group to allow port 3000"
echo "2. Check server logs: tail -f ~/planapi-proxy/proxy.log" 