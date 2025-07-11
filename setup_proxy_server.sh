#!/bin/bash

echo "Starting proxy server setup..."

# Update system
sudo yum update -y

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install Nginx
sudo yum install -y nginx

# Create proxy server directory
mkdir -p ~/proxy-server
cd ~/proxy-server

# Create package.json
cat > package.json << 'EOF'
{
  "name": "recharge-proxy",
  "version": "1.0.0",
  "description": "Proxy server for PlanAPI.in",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "axios": "^1.6.0",
    "helmet": "^7.1.0"
  }
}
EOF

# Install dependencies
npm install

# Create the proxy server
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// PlanAPI.in configuration
const PLAN_API_BASE_URL = 'https://planapi.in/api';
const API_KEY = '81bd9a2a-7857-406c-96aa-056967ba859a';
const API_ID = '3557';
const API_PASSWORD = 'Neela@1988';

// Helper function to make API calls with error handling
async function makeApiCall(url, params = {}) {
  try {
    console.log(`Making API call to: ${url}`);
    console.log('Params:', params);
    
    const response = await axios.get(url, {
      params,
      timeout: 25000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    
    console.log('API Response status:', response.status);
    return response.data;
  } catch (error) {
    console.error('API call failed:', error.message);
    if (error.response) {
      console.error('Error response:', error.response.data);
      throw new Error(`API Error: ${error.response.status} - ${error.response.data.message || error.response.data}`);
    } else if (error.request) {
      throw new Error('Network Error: Unable to reach the API');
    } else {
      throw new Error(`Request Error: ${error.message}`);
    }
  }
}

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Recharge Proxy Server is running',
    timestamp: new Date().toISOString()
  });
});

// Operator detection endpoint
app.get('/api/operator-detection', async (req, res) => {
  try {
    const { mobile } = req.query;
    
    if (!mobile) {
      return res.status(400).json({ error: 'Mobile number is required' });
    }
    
    const url = `${PLAN_API_BASE_URL}/Operatordetection.php`;
    const params = {
      api_key: API_KEY,
      userid: API_ID,
      password: API_PASSWORD,
      mobile: mobile
    };
    
    const data = await makeApiCall(url, params);
    res.json(data);
  } catch (error) {
    console.error('Operator detection error:', error);
    res.status(500).json({ 
      error: 'Failed to detect operator',
      message: error.message 
    });
  }
});

// Mobile plans endpoint
app.get('/api/mobile-plans', async (req, res) => {
  try {
    const { operatorcode, circle } = req.query;
    
    if (!operatorcode || !circle) {
      return res.status(400).json({ 
        error: 'Operator code and circle are required' 
      });
    }
    
    const url = `${PLAN_API_BASE_URL}/MobilePlans.php`;
    const params = {
      api_key: API_KEY,
      userid: API_ID,
      password: API_PASSWORD,
      operatorcode: operatorcode,
      circle: circle
    };
    
    const data = await makeApiCall(url, params);
    res.json(data);
  } catch (error) {
    console.error('Mobile plans error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch mobile plans',
      message: error.message 
    });
  }
});

// R-offers endpoint
app.get('/api/r-offers', async (req, res) => {
  try {
    const { operatorcode, circle } = req.query;
    
    if (!operatorcode || !circle) {
      return res.status(400).json({ 
        error: 'Operator code and circle are required' 
      });
    }
    
    const url = `${PLAN_API_BASE_URL}/Roffers.php`;
    const params = {
      api_key: API_KEY,
      userid: API_ID,
      password: API_PASSWORD,
      operatorcode: operatorcode,
      circle: circle
    };
    
    const data = await makeApiCall(url, params);
    res.json(data);
  } catch (error) {
    console.error('R-offers error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch R-offers',
      message: error.message 
    });
  }
});

// Recharge endpoint
app.post('/api/recharge', async (req, res) => {
  try {
    const { mobile, operatorcode, circle, amount, orderId } = req.body;
    
    if (!mobile || !operatorcode || !circle || !amount || !orderId) {
      return res.status(400).json({ 
        error: 'All fields are required: mobile, operatorcode, circle, amount, orderId' 
      });
    }
    
    const url = `${PLAN_API_BASE_URL}/Recharge.php`;
    const params = {
      api_key: API_KEY,
      userid: API_ID,
      password: API_PASSWORD,
      mobile: mobile,
      operatorcode: operatorcode,
      circle: circle,
      amount: amount,
      orderId: orderId
    };
    
    const data = await makeApiCall(url, params);
    res.json(data);
  } catch (error) {
    console.error('Recharge error:', error);
    res.status(500).json({ 
      error: 'Failed to process recharge',
      message: error.message 
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: error.message 
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    path: req.originalUrl 
  });
});

app.listen(PORT, () => {
  console.log(`Proxy server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/`);
});
EOF

# Start the server with PM2
pm2 start server.js --name "recharge-proxy"
pm2 save
pm2 startup

# Configure Nginx
sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
        }
    }
}
EOF

# Start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "Setup complete!"
echo "Server should be running at: http://56.228.11.165"
echo ""
echo "To check status:"
echo "  pm2 status"
echo "  sudo systemctl status nginx"
echo ""
echo "To view logs:"
echo "  pm2 logs recharge-proxy"
echo "  sudo tail -f /var/log/nginx/error.log" 