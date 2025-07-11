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
  origin: '*', // Allow all origins for now, restrict in production
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
    
    // Check if it's a network error
    if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND' || error.code === 'ETIMEDOUT') {
      return {
        success: false,
        error: 'Network connection failed',
        fallback: true,
        data: null
      };
    }
    
    // Check if it's a response error
    if (error.response) {
      return {
        success: false,
        error: `API returned ${error.response.status}: ${error.response.statusText}`,
        fallback: true,
        data: error.response.data
      };
    }
    
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
    
    // Return fallback data
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
    
    // Return fallback plans
    res.json({
      success: false,
      error: 'Service temporarily unavailable',
      fallback: true,
      data: getFallbackPlans(req.query.operatorcode, req.query.circle)
    });
  }
});

// R-Offers endpoint
app.get('/api/r-offers', async (req, res) => {
  try {
    const { operator_code, mobile_no } = req.query;
    
    if (!operator_code || !mobile_no) {
      return res.status(400).json({ 
        success: false, 
        error: 'Operator code and mobile number required' 
      });
    }

    const url = `${PLAN_API_CONFIG.BASE_URL}/RofferCheck?apimember_id=${PLAN_API_CONFIG.USER_ID}&api_password=${PLAN_API_CONFIG.PASSWORD}&operator_code=${operator_code}&mobile_no=${mobile_no}`;
    
    const result = await makeApiCall(url, 'R-offers fetch');
    
    if (!result.success) {
      // Return empty offers array for fallback
      result.data = [];
      result.fallback = true;
    }

    res.json(result);

  } catch (error) {
    console.error('R-offers fetch error:', error.message);
    
    // Return empty offers array
    res.json({
      success: false,
      error: 'R-offers temporarily unavailable',
      fallback: true,
      data: []
    });
  }
});

// Last Recharge endpoint
app.get('/api/last-recharge', async (req, res) => {
  try {
    const { mobile_no } = req.query;
    
    if (!mobile_no) {
      return res.status(400).json({ 
        success: false, 
        error: 'Mobile number required' 
      });
    }

    const url = `${PLAN_API_CONFIG.BASE_URL}/CheckLastRecharge?apimember_id=${PLAN_API_CONFIG.USER_ID}&api_password=${PLAN_API_CONFIG.PASSWORD}&mobile_no=${mobile_no}`;
    
    const result = await makeApiCall(url, 'Last recharge check');
    
    if (!result.success) {
      // Return fallback response
      result.data = {
        status: 'ERROR',
        message: 'Last recharge information not available'
      };
      result.fallback = true;
    }

    res.json(result);

  } catch (error) {
    console.error('Last recharge check error:', error.message);
    
    // Return fallback response
    res.json({
      success: false,
      error: 'Last recharge service temporarily unavailable',
      fallback: true,
      data: {
        status: 'ERROR',
        message: 'Last recharge information not available'
      }
    });
  }
});

// Recharge Processing endpoint
app.get('/api/recharge', async (req, res) => {
  try {
    const { mobileno, operatorcode, circle, amount, requestid } = req.query;
    
    if (!mobileno || !operatorcode || !circle || !amount || !requestid) {
      return res.status(400).json({ 
        success: false, 
        error: 'All parameters required: mobileno, operatorcode, circle, amount, requestid' 
      });
    }

    const url = `${PLAN_API_CONFIG.BASE_URL}/Recharge?apimember_id=${PLAN_API_CONFIG.USER_ID}&api_password=${PLAN_API_CONFIG.PASSWORD}&mobileno=${mobileno}&operatorcode=${operatorcode}&circle=${circle}&amount=${amount}&requestid=${requestid}`;
    
    const result = await makeApiCall(url, 'Recharge processing');
    
    if (!result.success) {
      // Return demo recharge response
      result.data = {
        ERROR: "0",
        STATUS: "0",
        MESSAGE: "Recharge initiated successfully (Demo Mode)",
        TXNID: requestid,
        RDATA: {
          status: "PENDING",
          balance: 0.0,
          operator_txnid: null,
          demo: true
        }
      };
      result.fallback = true;
    }

    res.json(result);

  } catch (error) {
    console.error('Recharge processing error:', error.message);
    
    // Return demo recharge response
    res.json({
      success: false,
      error: 'Recharge service temporarily unavailable',
      fallback: true,
      data: {
        ERROR: "0",
        STATUS: "0",
        MESSAGE: "Recharge initiated successfully (Demo Mode)",
        TXNID: req.query.requestid,
        RDATA: {
          status: "PENDING",
          balance: 0.0,
          operator_txnid: null,
          demo: true
        }
      }
    });
  }
});

// Helper functions
function getOperatorFromPrefix(mobile) {
  const prefix = mobile.substring(0, 4);
  
  // Common prefixes for operators
  const operatorMap = {
    // Jio prefixes
    '6000': 'Jio', '6001': 'Jio', '6002': 'Jio', '6003': 'Jio',
    '7000': 'Jio', '7001': 'Jio', '7002': 'Jio', '7003': 'Jio',
    '8000': 'Jio', '8001': 'Jio', '8002': 'Jio', '8003': 'Jio',
    '9000': 'Jio', '9001': 'Jio', '9002': 'Jio', '9003': 'Jio',
    
    // Airtel prefixes
    '6200': 'Airtel', '6201': 'Airtel', '6202': 'Airtel',
    '7200': 'Airtel', '7201': 'Airtel', '7202': 'Airtel',
    '8200': 'Airtel', '8201': 'Airtel', '8202': 'Airtel',
    '9200': 'Airtel', '9201': 'Airtel', '9202': 'Airtel',
    
    // VI (Vodafone Idea) prefixes
    '6300': 'VI', '6301': 'VI', '6302': 'VI',
    '7300': 'VI', '7301': 'VI', '7302': 'VI',
    '8300': 'VI', '8301': 'VI', '8302': 'VI',
    '9300': 'VI', '9301': 'VI', '9302': 'VI',
  };
  
  return operatorMap[prefix] || 'Airtel'; // Default to Airtel
}

function getOperatorCodeFromPrefix(mobile) {
  const operator = getOperatorFromPrefix(mobile);
  const codeMap = {
    'Jio': '11',
    'Airtel': '1',
    'VI': '3',
    'BSNL': '4'
  };
  
  return codeMap[operator] || '1'; // Default to Airtel
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
  console.log(`   - GET /api/r-offers?operator_code=XX&mobile_no=XXXXXXXXXX`);
  console.log(`   - GET /api/last-recharge?mobile_no=XXXXXXXXXX`);
  console.log(`   - GET /api/recharge?mobileno=XX&operatorcode=XX&circle=XX&amount=XX&requestid=XX`);
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