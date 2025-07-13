const express = require('express');
const axios = require('axios');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3001;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Plan API configuration
const PLAN_API_BASE_URL = 'https://planapi.in/api';
const API_USER_ID = process.env.API_USER_ID || '3557';
const API_PASSWORD = process.env.API_PASSWORD || 'Neela@1988';

// Robotics Exchange API configuration
const ROBOTICS_API_BASE_URL = 'https://api.roboticexchange.in/Robotics/webservice';
const ROBOTICS_API_MEMBER_ID = process.env.ROBOTICS_API_MEMBER_ID || '3425';
const ROBOTICS_API_PASSWORD = process.env.ROBOTICS_API_PASSWORD || 'Neela@415263';

// Error handler middleware
const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
};

// Plan API proxy routes
app.get('/api/planapi/*', async (req, res, next) => {
  try {
    const endpoint = req.params[0];
    const queryParams = req.query;
    
    console.log(`Plan API Request - Endpoint: ${endpoint}`);
    console.log(`Plan API Request - Params:`, queryParams);

    const response = await axios.get(`${PLAN_API_BASE_URL}/${endpoint}`, {
      params: queryParams,
      headers: {
        'User-Agent': 'SamyPay-Mobile-App/1.0',
        'Accept': 'application/json',
      },
      timeout: 30000
    });

    console.log(`Plan API Response Status: ${response.status}`);
    console.log(`Plan API Response Data:`, response.data);

    res.json(response.data);
  } catch (error) {
    console.error('Plan API Error:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Robotics Exchange API proxy routes
app.get('/api/robotics/*', async (req, res, next) => {
  try {
    const endpoint = req.params[0];
    const queryParams = req.query;
    
    console.log(`Robotics API Request - Endpoint: ${endpoint}`);
    console.log(`Robotics API Request - Params:`, queryParams);

    const response = await axios.get(`${ROBOTICS_API_BASE_URL}/${endpoint}`, {
      params: queryParams,
      headers: {
        'User-Agent': 'SamyPay-Mobile-App/1.0',
        'Accept': 'application/json',
      },
      timeout: 30000
    });

    console.log(`Robotics API Response Status: ${response.status}`);
    console.log(`Robotics API Response Data:`, response.data);

    res.json(response.data);
  } catch (error) {
    console.error('Robotics API Error:', error.message);
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Legacy operator check endpoint (for backward compatibility)
app.get('/api/operator-check', async (req, res, next) => {
  try {
    const { mobileNumber } = req.query;

    if (!mobileNumber || !/^\d{10}$/.test(mobileNumber)) {
      return res.status(400).json({
        error: 'Invalid mobile number',
        message: 'Please provide a valid 10-digit mobile number'
      });
    }

    const response = await axios.get(`${PLAN_API_BASE_URL}/Mobile/OperatorFetchNew`, {
      params: {
        ApiUserID: API_USER_ID,
        ApiPassword: API_PASSWORD,
        Mobileno: mobileNumber
      }
    });

    res.json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      next(error);
    }
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      planApi: PLAN_API_BASE_URL,
      roboticsApi: ROBOTICS_API_BASE_URL
    }
  });
});

app.use(errorHandler);

app.listen(port, () => {
  console.log(`Proxy server running on port ${port}`);
  console.log(`Plan API: ${PLAN_API_BASE_URL}`);
  console.log(`Robotics API: ${ROBOTICS_API_BASE_URL}`);
}); 