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
const PLAN_API_BASE_URL = 'https://planapi.in/api/Mobile';
const API_USER_ID = '3557';
const API_PASSWORD = 'Neela@1988';

// Helper function to make API calls with error handling
async function makeApiCall(url, params = {}) {
  try {
    console.log('Making API call to:', url);
    console.log('Params:', params);
    
    const response = await axios.get(url, {
      params,
      timeout: 25000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    
    console.log('Response status:', response.status);
    console.log('Response data:', JSON.stringify(response.data, null, 2));
    
    return response.data;
  } catch (error) {
    console.error('API call failed:', error.message);
    if (error.response) {
      console.error('Error response:', error.response.status, error.response.data);
      throw new Error(`API Error: ${error.response.status} - ${error.response.statusText}`);
    }
    throw error;
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

// Operator Detection API (Updated with correct endpoint)
app.get('/api/operator-detection', async (req, res) => {
  try {
    const { mobile } = req.query;
    
    if (!mobile) {
      return res.status(400).json({
        error: 'Missing required parameter: mobile'
      });
    }
    
    const url = `${PLAN_API_BASE_URL}/OperatorFetchNew`;
    const params = {
      ApiUserID: API_USER_ID,
      ApiPassword: API_PASSWORD,
      Mobileno: mobile
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

// Mobile Plans API (Updated with correct endpoint)
app.get('/api/mobile-plans', async (req, res) => {
  try {
    const { operatorcode, circle } = req.query;
    
    if (!operatorcode || !circle) {
      return res.status(400).json({
        error: 'Missing required parameters: operatorcode, circle'
      });
    }
    
    const url = `${PLAN_API_BASE_URL}/NewMobilePlans`;
    const params = {
      apimember_id: API_USER_ID,
      api_password: API_PASSWORD,
      operatorcode: operatorcode,
      cricle: circle  // Note: API uses 'cricle' not 'circle'
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

// R-Offers API (Updated with correct parameters)
app.get('/api/r-offers', async (req, res) => {
  try {
    const { operator_code, mobile_no } = req.query;
    
    if (!operator_code || !mobile_no) {
      return res.status(400).json({
        error: 'Missing required parameters: operator_code, mobile_no'
      });
    }
    
    const url = `${PLAN_API_BASE_URL}/RofferCheck`;
    const params = {
      apimember_id: API_USER_ID,
      api_password: API_PASSWORD,
      operator_code: operator_code,
      mobile_no: mobile_no
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

// Live Recharge API (NEW)
app.post('/api/recharge', async (req, res) => {
  try {
    const { mobile, operator_code, circle, amount, order_id } = req.body;
    
    if (!mobile || !operator_code || !circle || !amount || !order_id) {
      return res.status(400).json({
        error: 'Missing required parameters: mobile, operator_code, circle, amount, order_id'
      });
    }
    
    // Note: You'll need to get the actual recharge endpoint from PlanAPI.in documentation
    // This is a placeholder implementation
    const url = `${PLAN_API_BASE_URL}/Recharge`;
    const params = {
      apimember_id: API_USER_ID,
      api_password: API_PASSWORD,
      mobile: mobile,
      operator_code: operator_code,
      circle: circle,
      amount: amount,
      order_id: order_id
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

// Start server
app.listen(PORT, () => {
  console.log(`Proxy server running on port ${PORT}`);
}); 