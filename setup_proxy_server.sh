#!/bin/bash

# Step 1: Connect to your EC2 instance
echo "Connecting to EC2 instance..."
# ssh -i "rechager.pem" ec2-user@56.228.11.165

# Step 2: Update system and install Node.js
echo "Updating system and installing Node.js..."
sudo yum update -y
sudo yum install -y nodejs npm

# Verify installation
node --version
npm --version

# Step 3: Create proxy application
echo "Setting up proxy application..."
mkdir -p ~/planapi-proxy
cd ~/planapi-proxy

# Initialize npm project
npm init -y

# Install dependencies
npm install express http-proxy-middleware cors dotenv

# Step 4: Create the proxy server file
cat > server.js << 'EOF'
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Query params:', req.query);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    server: 'PlanAPI Proxy',
    version: '1.0.0'
  });
});

// Proxy middleware for Plan API
const planApiProxy = createProxyMiddleware({
  target: 'https://planapi.in',
  changeOrigin: true,
  pathRewrite: {
    '^/api/planapi': '/api'
  },
  onProxyReq: (proxyReq, req, res) => {
    // Remove forwarding headers to ensure PlanAPI sees the proxy's IP
    proxyReq.removeHeader('x-forwarded-for');
    proxyReq.removeHeader('x-forwarded-host');
    proxyReq.removeHeader('x-forwarded-proto');
    
    console.log('Proxying request to:', proxyReq.path);
    console.log('Target URL:', `https://planapi.in${proxyReq.path}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log('Received response with status:', proxyRes.statusCode);
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err.message);
    res.status(500).json({ 
      error: 'Proxy error', 
      message: err.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Use the proxy for Plan API requests
app.use('/api/planapi', planApiProxy);

// Default route
app.get('/', (req, res) => {
  res.json({
    message: 'PlanAPI Proxy Server',
    endpoints: {
      health: '/health',
      planapi: '/api/planapi/Mobile/OperatorFetchNew'
    },
    timestamp: new Date().toISOString()
  });
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Proxy server running on port ${PORT}`);
  console.log(`📊 Health check: http://56.228.11.165:${PORT}/health`);
  console.log(`📱 Plan API proxy: http://56.228.11.165:${PORT}/api/planapi/Mobile/OperatorFetchNew`);
  console.log(`🌐 Server accessible at: http://56.228.11.165:${PORT}`);
});
EOF

# Step 5: Create a simple startup script
cat > start.sh << 'EOF'
#!/bin/bash
echo "Starting PlanAPI Proxy Server..."
cd ~/planapi-proxy
npm start
EOF

chmod +x start.sh

# Step 6: Create package.json scripts
cat > package.json << 'EOF'
{
  "name": "planapi-proxy",
  "version": "1.0.0",
  "description": "Proxy server for PlanAPI to handle IP whitelisting",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "pm2:start": "pm2 start server.js --name planapi-proxy",
    "pm2:stop": "pm2 stop planapi-proxy",
    "pm2:restart": "pm2 restart planapi-proxy",
    "pm2:logs": "pm2 logs planapi-proxy"
  },
  "keywords": ["proxy", "planapi", "aws", "ec2"],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "http-proxy-middleware": "^2.0.6",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  }
}
EOF

# Step 7: Install PM2 for process management (optional but recommended)
sudo npm install -g pm2

# Step 7.5: Configure Firewall
echo "Configuring firewall..."
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --zone=public --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

# Step 8: Test the setup
echo "Testing the proxy setup..."
echo "Starting server in background..."
nohup npm start > proxy.log 2>&1 &

# Wait a few seconds for server to start
sleep 5

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:3000/health | jq . || curl -s http://localhost:3000/health

echo ""
echo "✅ Proxy setup complete!"
echo "🌐 Server running at: http://56.228.11.165:3000"
echo "📊 Health check: http://56.228.11.165:3000/health"
echo "📱 API endpoint: http://56.228.11.165:3000/api/planapi/Mobile/OperatorFetchNew"
echo ""
echo "To start with PM2: npm run pm2:start"
echo "To view logs: npm run pm2:logs"
echo "To stop: npm run pm2:stop" 