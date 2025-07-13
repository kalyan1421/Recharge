const express = require('express');
const axios = require('axios');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: true,
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: (process.env.RATE_LIMIT_WINDOW || 15) * 60 * 1000,
  max: process.env.RATE_LIMIT_MAX || 100,
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Mobile Recharge API Proxy',
    version: '2.0.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Mobile Recharge API Proxy Server',
    version: '2.0.0',
    status: 'running',
    endpoints: [
      'GET /health - Health check',
      'GET /api/operator-detection - Detect operator',
      'GET /api/mobile-plans - Get mobile plans',
      'POST /api/recharge - Process recharge',
      'GET /api/wallet-balance - Check wallet balance',
      'GET /api/recharge-status - Check recharge status'
    ]
  });
});

// API Configuration
const PLANAPI_CONFIG = {
  baseUrl: 'https://planapi.in/api/Mobile',
  userId: process.env.PLANAPI_USER_ID || '3557',
  password: process.env.PLANAPI_PASSWORD || 'Neela@1988',
  token: process.env.PLANAPI_TOKEN || '81bd9a2a-7857-406c-96aa-056967ba859a'
};

const ROBOTICS_CONFIG = {
  baseUrl: 'https://api.roboticexchange.in/Robotics/webservice',
  memberId: process.env.ROBOTICS_MEMBER_ID || '3425',
  apiPassword: process.env.ROBOTICS_API_PASSWORD || 'Apipassword'
};

// Operator Detection Endpoint
app.get('/api/operator-detection', async (req, res) => {
  try {
    const { mobile } = req.query;
    
    if (!mobile || mobile.length !== 10) {
      return res.status(400).json({
        success: false,
        error: 'Invalid mobile number. Please provide a 10-digit number.'
      });
    }

    console.log(`[OPERATOR] Detecting operator for: ${mobile}`);

    const response = await axios.get(`${PLANAPI_CONFIG.baseUrl}/OperatorFetchNew`, {
      params: {
        ApiUserID: PLANAPI_CONFIG.userId,
        ApiPassword: PLANAPI_CONFIG.password,
        Mobileno: mobile
      },
      timeout: 30000
    });

    console.log(`[OPERATOR] Response:`, response.data);

    res.json({
      success: true,
      data: response.data,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[OPERATOR] Error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to detect operator',
      message: error.response?.data?.Message || error.message
    });
  }
});

// Mobile Plans Endpoint
app.get('/api/mobile-plans', async (req, res) => {
  try {
    const { operatorcode, circle } = req.query;
    
    if (!operatorcode || !circle) {
      return res.status(400).json({
        success: false,
        error: 'Operator code and circle are required'
      });
    }

    console.log(`[PLANS] Fetching plans for operator: ${operatorcode}, circle: ${circle}`);

    const response = await axios.get(`${PLANAPI_CONFIG.baseUrl}/Operatorplan`, {
      params: {
        apimember_id: PLANAPI_CONFIG.userId,
        api_password: PLANAPI_CONFIG.password,
        operatorcode: operatorcode,
        cricle: circle
      },
      timeout: 30000
    });

    res.json({
      success: true,
      data: response.data,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[PLANS] Error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch mobile plans',
      message: error.response?.data?.Message || error.message
    });
  }
});

// Recharge Endpoint
app.post('/api/recharge', async (req, res) => {
  try {
    const { mobile, operator_code, circle, amount, unique_id } = req.body;
    
    // Validate required fields
    if (!mobile || !operator_code || !circle || !amount || !unique_id) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        required: ['mobile', 'operator_code', 'circle', 'amount', 'unique_id']
      });
    }

    console.log(`[RECHARGE] Processing recharge:`, req.body);

    // Convert operator codes (PlanAPI to Robotics)
    const operatorMapping = {
      '2': 'AT',   // Airtel
      '11': 'JO',  // Jio
      '23': 'VI',  // Vodafone
      '6': 'VI',   // Idea
      '5': 'BS',   // BSNL
      '4': 'BS'    // BSNL Topup
    };

    const roboticsOperatorCode = operatorMapping[operator_code] || operator_code;

    const response = await axios.get(`${ROBOTICS_CONFIG.baseUrl}/GetMobileRecharge`, {
      params: {
        Apimember_id: ROBOTICS_CONFIG.memberId,
        Api_password: ROBOTICS_CONFIG.apiPassword,
        Mobile_no: mobile,
        Operator_code: roboticsOperatorCode,
        Amount: amount,
        Member_request_txnid: unique_id,
        Circle: circle
      },
      timeout: 30000
    });

    console.log(`[RECHARGE] Response:`, response.data);

    // Process response
    const data = response.data;
    const error = data.ERROR?.toString() || '1';
    const status = data.STATUS?.toString() || '3';

    if (error === '0' && status === '1') {
      res.json({
        success: true,
        transactionId: unique_id,
        orderId: data.ORDERID,
        operatorTxnId: data.OPTRANSID,
        status: 'SUCCESS',
        message: data.MESSAGE || 'Recharge successful',
        amount: parseFloat(amount),
        balance: parseFloat(data.CLOSINGBAL || '0'),
        commission: parseFloat(data.COMMISSION || '0'),
        timestamp: new Date().toISOString()
      });
    } else if (error === '1' && status === '2') {
      res.json({
        success: true,
        transactionId: unique_id,
        orderId: data.ORDERID,
        status: 'PROCESSING',
        message: 'Recharge is being processed',
        amount: parseFloat(amount),
        balance: parseFloat(data.CLOSINGBAL || '0'),
        timestamp: new Date().toISOString()
      });
    } else {
      res.json({
        success: false,
        transactionId: unique_id,
        status: 'FAILED',
        message: data.MESSAGE || 'Recharge failed',
        amount: parseFloat(amount),
        errorCode: error,
        timestamp: new Date().toISOString()
      });
    }

  } catch (error) {
    console.error('[RECHARGE] Error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Recharge processing failed',
      message: error.response?.data?.MESSAGE || error.message
    });
  }
});

// Wallet Balance Endpoint
app.get('/api/wallet-balance', async (req, res) => {
  try {
    console.log(`[WALLET] Checking wallet balance`);

    const response = await axios.get(`${ROBOTICS_CONFIG.baseUrl}/GetWalletBalance`, {
      params: {
        Apimember_id: ROBOTICS_CONFIG.memberId,
        Api_password: ROBOTICS_CONFIG.apiPassword
      },
      timeout: 30000
    });

    console.log(`[WALLET] Response:`, response.data);

    const data = response.data;
    
    if (data.Errorcode === '0' && data.Status === '1') {
      res.json({
        success: true,
        buyerBalance: parseFloat(data.BuyerWalletBalance || '0'),
        sellerBalance: parseFloat(data.SellerWalletBalance || '0'),
        timestamp: new Date().toISOString()
      });
    } else {
      res.json({
        success: false,
        error: data.Message || 'Failed to get wallet balance',
        timestamp: new Date().toISOString()
      });
    }

  } catch (error) {
    console.error('[WALLET] Error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to check wallet balance',
      message: error.response?.data?.Message || error.message
    });
  }
});

// Recharge Status Check Endpoint
app.get('/api/recharge-status', async (req, res) => {
  try {
    const { transaction_id } = req.query;
    
    if (!transaction_id) {
      return res.status(400).json({
        success: false,
        error: 'Transaction ID is required'
      });
    }

    console.log(`[STATUS] Checking status for transaction: ${transaction_id}`);

    const response = await axios.get(`${ROBOTICS_CONFIG.baseUrl}/GetStatus`, {
      params: {
        Apimember_id: ROBOTICS_CONFIG.memberId,
        Api_password: ROBOTICS_CONFIG.apiPassword,
        Member_request_txnid: transaction_id
      },
      timeout: 30000
    });

    console.log(`[STATUS] Response:`, response.data);

    const data = response.data;
    const error = data.ERROR?.toString() || '1';
    const status = data.STATUS?.toString() || '3';

    let rechargeStatus = 'UNKNOWN';
    let isSuccess = false;

    if (error === '0' && status === '1') {
      rechargeStatus = 'SUCCESS';
      isSuccess = true;
    } else if (error === '1' && status === '2') {
      rechargeStatus = 'PROCESSING';
      isSuccess = true;
    } else {
      rechargeStatus = 'FAILED';
      isSuccess = false;
    }

    res.json({
      success: isSuccess,
      transactionId: transaction_id,
      orderId: data.ORDERID,
      operatorTxnId: data.OPTRANSID,
      status: rechargeStatus,
      message: data.MESSAGE || 'Status check completed',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[STATUS] Error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to check recharge status',
      message: error.response?.data?.Message || error.message
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.path}`
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Mobile Recharge API Proxy Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📱 PlanAPI User ID: ${PLANAPI_CONFIG.userId}`);
  console.log(`🤖 Robotics Member ID: ${ROBOTICS_CONFIG.memberId}`);
});

module.exports = app; 