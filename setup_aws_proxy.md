# AWS EC2 Proxy Server Setup Guide

## Current Status
✅ **Flutter App Updated** - Your app is configured to use the proxy
❌ **Proxy Server Not Running** - Need to deploy to EC2

## Step 1: Connect to Your EC2 Instance

```bash
# Replace with your actual key file path
ssh -i ~/Downloads/recharge-proxy-key.pem ubuntu@56.228.11.165
```

## Step 2: Install Node.js and Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Verify installation
node --version  # Should show v18.x.x
npm --version   # Should show 9.x.x
```

## Step 3: Create Project Directory

```bash
# Create project directory
mkdir ~/recharge-proxy && cd ~/recharge-proxy

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express cors helmet morgan axios rate-limiter-flexible dotenv
```

## Step 4: Create Server Files

### Create server.js:
```bash
nano server.js
```

Copy and paste this content:

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const axios = require('axios');
const { RateLimiterMemory } = require('rate-limiter-flexible');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Allow all origins for now
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));

// Rate limiting
const rateLimiter = new RateLimiterMemory({
  keyBy: (req) => req.ip,
  points: 100, // 100 requests
  duration: 60, // per 60 seconds
});

// Rate limit middleware
const rateLimitMiddleware = async (req, res, next) => {
  try {
    await rateLimiter.consume(req.ip);
    next();
  } catch (rejRes) {
    res.status(429).json({ 
      success: false, 
      error: 'Too many requests. Please try again later.' 
    });
  }
};

app.use(rateLimitMiddleware);

// API Configuration
const PLAN_API_CONFIG = {
  USER_ID: process.env.PLAN_API_USER || '3557',
  PASSWORD: process.env.PLAN_API_PASSWORD || 'Neela@1988',
  BASE_URL: 'https://planapi.in/api/Mobile'
};

// Helper function to make API calls with error handling
async function makeApiCall(url, errorContext = 'API call') {
  try {
    console.log(`Making API call to: ${url}`);
    const response = await axios.get(url, { 
      timeout: 15000,
      headers: {
        'User-Agent': 'RechargeProxy/1.0',
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`API Response Status: ${response.status}`);
    console.log(`API Response Data:`, JSON.stringify(response.data, null, 2));
    
    return {
      success: true,
      data: response.data,
      source: 'planapi'
    };
  } catch (error) {
    console.error(`${errorContext} error:`, error.message);
    
    return {
      success: false,
      error: error.message,
      fallback: true,
      data: null
    };
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    server: 'AWS EC2 Proxy',
    version: '1.0.0'
  });
});

// Operator Detection endpoint
app.get('/api/operator-detection', async (req, res) => {
  try {
    const { mobile } = req.query;
    
    if (!mobile || mobile.length !== 10) {
      return res.status(400).json({ 
        success: false, 
        error: 'Valid 10-digit mobile number required' 
      });
    }

    const url = `${PLAN_API_CONFIG.BASE_URL}/OperatorFetchNew?ApiUserID=${PLAN_API_CONFIG.USER_ID}&ApiPassword=${PLAN_API_CONFIG.PASSWORD}&Mobileno=${mobile}`;
    
    const result = await makeApiCall(url, 'Operator detection');
    
    if (!result.success) {
      // Return fallback operator info
      const fallbackData = {
        ERROR: "1",
        MESSAGE: "Auto-detection unavailable, please select manually",
        Operator: getOperatorFromPrefix(mobile),
        OpCode: getOperatorCodeFromPrefix(mobile),
        Circle: "Delhi",
        CircleCode: "10",
        Mobile: mobile,
        STATUS: "0"
      };
      
      result.data = fallbackData;
      result.fallback = true;
    }

    res.json(result);

  } catch (error) {
    console.error('Operator detection error:', error.message);
    
    res.json({
      success: false,
      error: 'Service temporarily unavailable',
      fallback: true,
      data: {
        ERROR: "1",
        MESSAGE: "Auto-detection unavailable, please select manually",
        Operator: getOperatorFromPrefix(req.query.mobile),
        OpCode: getOperatorCodeFromPrefix(req.query.mobile),
        Circle: "Delhi",
        CircleCode: "10",
        Mobile: req.query.mobile,
        STATUS: "0"
      }
    });
  }
});

// Mobile Plans endpoint
app.get('/api/mobile-plans', async (req, res) => {
  try {
    const { operatorcode, circle } = req.query;
    
    if (!operatorcode || !circle) {
      return res.status(400).json({ 
        success: false, 
        error: 'Operator code and circle required' 
      });
    }

    const url = `${PLAN_API_CONFIG.BASE_URL}/NewMobilePlans?apimember_id=${PLAN_API_CONFIG.USER_ID}&api_password=${PLAN_API_CONFIG.PASSWORD}&operatorcode=${operatorcode}&cricle=${circle}`;
    
    const result = await makeApiCall(url, 'Mobile plans fetch');
    
    if (!result.success) {
      // Return fallback plans
      const fallbackData = getFallbackPlans(operatorcode, circle);
      result.data = fallbackData;
      result.fallback = true;
    }

    res.json(result);

  } catch (error) {
    console.error('Plans fetch error:', error.message);
    
    res.json({
      success: false,
      error: 'Service temporarily unavailable',
      fallback: true,
      data: getFallbackPlans(req.query.operatorcode, req.query.circle)
    });
  }
});

// Helper functions
function getOperatorFromPrefix(mobile) {
  const prefix = mobile.substring(0, 4);
  
  const operatorMap = {
    '6000': 'Jio', '6001': 'Jio', '6002': 'Jio', '6003': 'Jio',
    '7000': 'Jio', '7001': 'Jio', '7002': 'Jio', '7003': 'Jio',
    '8000': 'Jio', '8001': 'Jio', '8002': 'Jio', '8003': 'Jio',
    '9000': 'Jio', '9001': 'Jio', '9002': 'Jio', '9003': 'Jio',
    
    '6200': 'Airtel', '6201': 'Airtel', '6202': 'Airtel',
    '7200': 'Airtel', '7201': 'Airtel', '7202': 'Airtel',
    '8200': 'Airtel', '8201': 'Airtel', '8202': 'Airtel',
    '9200': 'Airtel', '9201': 'Airtel', '9202': 'Airtel',
    
    '6300': 'VI', '6301': 'VI', '6302': 'VI',
    '7300': 'VI', '7301': 'VI', '7302': 'VI',
    '8300': 'VI', '8301': 'VI', '8302': 'VI',
    '9300': 'VI', '9301': 'VI', '9302': 'VI',
  };
  
  return operatorMap[prefix] || 'Airtel';
}

function getOperatorCodeFromPrefix(mobile) {
  const operator = getOperatorFromPrefix(mobile);
  const codeMap = {
    'Jio': '11',
    'Airtel': '1',
    'VI': '3',
    'BSNL': '4'
  };
  
  return codeMap[operator] || '1';
}

function getFallbackPlans(operatorcode, circle) {
  const operatorName = getOperatorName(operatorcode);
  const circleName = getCircleName(circle);
  
  return {
    ERROR: "0",
    STATUS: "0",
    Operator: operatorName,
    Circle: circleName,
    RDATA: {
      "Truly Unlimited": [
        { rs: 199, validity: "28 days", desc: "Unlimited Voice + 2GB/day + 100 SMS/day" },
        { rs: 399, validity: "56 days", desc: "Unlimited Voice + 2.5GB/day + 100 SMS/day" },
        { rs: 599, validity: "84 days", desc: "Unlimited Voice + 2GB/day + 100 SMS/day" },
        { rs: 719, validity: "84 days", desc: "Unlimited Voice + 1.5GB/day + 100 SMS/day" },
        { rs: 999, validity: "84 days", desc: "Unlimited Voice + 3GB/day + 100 SMS/day" }
      ],
      "Data": [
        { rs: 19, validity: "1 day", desc: "1GB Data" },
        { rs: 99, validity: "7 days", desc: "6GB Data" },
        { rs: 179, validity: "28 days", desc: "28GB Data" },
        { rs: 299, validity: "30 days", desc: "25GB Data" },
        { rs: 449, validity: "56 days", desc: "50GB Data" }
      ],
      "Talktime": [
        { rs: 10, validity: "7 days", desc: "Full Talktime" },
        { rs: 50, validity: "28 days", desc: "Full Talktime" },
        { rs: 100, validity: "56 days", desc: "Full Talktime" },
        { rs: 500, validity: "84 days", desc: "Full Talktime" }
      ],
      "Popular Plans": [
        { rs: 149, validity: "28 days", desc: "Unlimited Voice + 1GB/day + 100 SMS/day" },
        { rs: 239, validity: "28 days", desc: "Unlimited Voice + 1.5GB/day + 100 SMS/day" },
        { rs: 319, validity: "45 days", desc: "Unlimited Voice + 2GB/day + 100 SMS/day" },
        { rs: 479, validity: "56 days", desc: "Unlimited Voice + 1.5GB/day + 100 SMS/day" }
      ]
    },
    MESSAGE: "Fallback plans loaded successfully"
  };
}

function getOperatorName(code) {
  const operators = {
    '11': 'Jio',
    '1': 'Airtel',
    '3': 'VI',
    '4': 'BSNL'
  };
  return operators[code] || 'Unknown';
}

function getCircleName(code) {
  const circles = {
    '10': 'Delhi',
    '49': 'Andhra Pradesh',
    '92': 'Mumbai',
    '06': 'Karnataka',
    '40': 'Chennai',
    '94': 'Tamil Nadu',
    '95': 'Kerala',
    '98': 'Gujarat',
    '90': 'Maharashtra',
    '93': 'Madhya Pradesh',
    '70': 'Rajasthan',
    '31': 'Kolkata',
    '51': 'West Bengal',
    '52': 'Bihar',
    '53': 'Orissa',
    '54': 'UP East',
    '55': 'Jammu & Kashmir',
    '56': 'Assam',
    '96': 'Haryana',
    '97': 'UP West'
  };
  return circles[code] || 'Unknown';
}

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    message: `${req.method} ${req.path} not found`
  });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 AWS Recharge API Proxy Server`);
  console.log(`📡 Server running on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`🎯 API endpoints:`);
  console.log(`   - GET /api/operator-detection?mobile=XXXXXXXXXX`);
  console.log(`   - GET /api/mobile-plans?operatorcode=XX&circle=XX`);
  console.log(`📊 Proxy ready for Flutter app requests`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 Received SIGTERM, shutting down gracefully');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 Received SIGINT, shutting down gracefully');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

console.log('🎉 AWS Proxy Server initialized successfully!');
```

Save and exit: `Ctrl+X`, then `Y`, then `Enter`

### Create .env file:
```bash
nano .env
```

Add this content:
```
PORT=3000
PLAN_API_USER=3557
PLAN_API_PASSWORD=Neela@1988
NODE_ENV=production
```

Save and exit: `Ctrl+X`, then `Y`, then `Enter`

## Step 5: Configure Firewall

```bash
# Setup UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw --force enable

# Check status
sudo ufw status
```

## Step 6: Start the Server

```bash
# Start with PM2
pm2 start server.js --name recharge-proxy

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup

# Check status
pm2 status
pm2 logs recharge-proxy
```

## Step 7: Test the Server

```bash
# Test health check
curl http://localhost:3000/health

# Test from external (replace with your actual EC2 IP)
curl http://56.228.11.165:3000/health
```

## Step 8: Setup Nginx (Optional but Recommended)

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/recharge-proxy
```

Add this content:
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/recharge-proxy /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## Step 9: Update Flutter App (if needed)

If using Nginx, update your Flutter app to use port 80:

```dart
// In lib/core/constants/api_constants.dart
static const String proxyBaseUrl = 'http://56.228.11.165'; // Remove :3000
```

## Step 10: Test Integration

```bash
# Test all endpoints
curl "http://56.228.11.165/health"
curl "http://56.228.11.165/api/operator-detection?mobile=9876543210"
curl "http://56.228.11.165/api/mobile-plans?operatorcode=11&circle=49"
```

## Monitoring Commands

```bash
# Check server status
pm2 status

# View logs
pm2 logs recharge-proxy

# Restart server
pm2 restart recharge-proxy

# Check system resources
htop
free -h
df -h

# Check Nginx status
sudo systemctl status nginx

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Expected Results

After setup, your Flutter app should:
1. ✅ Connect to the proxy successfully
2. ✅ Get fallback plans when PlanAPI is blocked
3. ✅ Show operator detection (fallback mode)
4. ✅ Display mobile plans in the app

## Next Steps

1. **Test your Flutter app** - It should now work with fallback data
2. **Contact PlanAPI.in** - Request IP whitelisting for `56.228.11.165`
3. **Monitor logs** - Check `pm2 logs recharge-proxy` for any issues

Your proxy server will provide fallback responses until the IP is whitelisted by PlanAPI.in! 